import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/lead_model.dart';
import '../../core/constants/app_enums.dart';
import '../audit/audit_service.dart';

class ImportPreviewResult {
  final int totalRows;
  final List<LeadModel> validLeads;
  final List<String> invalidRows;
  final List<String> duplicatePhones;

  ImportPreviewResult({
    required this.totalRows,
    required this.validLeads,
    required this.invalidRows,
    required this.duplicatePhones,
  });

  int get validCount => validLeads.length;
  int get invalidCount => invalidRows.length;
  int get duplicateCount => duplicatePhones.length;
}

class LeadImportService {
  final SupabaseClient _supabase;
  final AuditService _auditService;

  LeadImportService({
    required SupabaseClient supabase,
    required AuditService auditService,
  })  : _supabase = supabase,
        _auditService = auditService;

  /// Analisa o conteúdo de um arquivo CSV e gera o preview com validação e deduplicação
  Future<ImportPreviewResult> previewCsv({
    required String csvContent,
    String defaultSource = 'Importação CSV',
  }) async {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) {
      return ImportPreviewResult(
        totalRows: 0,
        validLeads: [],
        invalidRows: [],
        duplicatePhones: [],
      );
    }

    // Identifica colunas pelo cabeçalho
    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    int nameIdx = header.indexWhere((c) => c.contains('nome') || c.contains('name'));
    int phoneIdx = header.indexWhere((c) => c.contains('tel') || c.contains('fone') || c.contains('phone'));
    int cityIdx = header.indexWhere((c) => c.contains('cidade') || c.contains('city'));
    int stateIdx = header.indexWhere((c) => c.contains('estado') || c.contains('uf') || c.contains('state'));
    int interestIdx = header.indexWhere((c) => c.contains('interesse') || c.contains('produto') || c.contains('interest'));
    int valueIdx = header.indexWhere((c) => c.contains('valor') || c.contains('preco') || c.contains('price'));
    int notesIdx = header.indexWhere((c) => c.contains('obs') || c.contains('nota') || c.contains('notes'));

    // Se não encontrou cabeçalho conhecido, assume ordem padrão das primeiras colunas
    if (nameIdx == -1) nameIdx = 0;
    if (phoneIdx == -1) phoneIdx = 1;

    // Busca telefones existentes no banco para checar duplicidade
    final existingPhonesResponse = await _supabase
        .from('leads')
        .select('phone');
    final existingPhoneSet = (existingPhonesResponse as List)
        .map((e) => PhoneUtils.cleanDigits(e['phone']?.toString() ?? ''))
        .where((digits) => digits.isNotEmpty)
        .toSet();

    final validLeads = <LeadModel>[];
    final invalidRows = <String>[];
    final duplicatePhones = <String>[];
    final seenInFile = <String>{};

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

      final name = (nameIdx >= 0 && nameIdx < row.length) ? row[nameIdx].toString().trim() : '';
      final rawPhone = (phoneIdx >= 0 && phoneIdx < row.length) ? row[phoneIdx].toString().trim() : '';

      final cleanPhone = PhoneUtils.cleanDigits(rawPhone);

      // Validação
      if (name.isEmpty) {
        invalidRows.add('Linha ${i + 1}: Nome ausente');
        continue;
      }

      if (!PhoneUtils.isValidBrazilianPhone(rawPhone)) {
        invalidRows.add('Linha ${i + 1} ($name): Telefone inválido "$rawPhone"');
        continue;
      }

      // Duplicidade
      if (seenInFile.contains(cleanPhone) || existingPhoneSet.contains(cleanPhone)) {
        duplicatePhones.add('$name ($rawPhone)');
        continue;
      }

      seenInFile.add(cleanPhone);

      final city = (cityIdx >= 0 && cityIdx < row.length) ? row[cityIdx].toString().trim() : '';
      final state = (stateIdx >= 0 && stateIdx < row.length) ? row[stateIdx].toString().trim() : '';
      final interest = (interestIdx >= 0 && interestIdx < row.length) ? row[interestIdx].toString().trim() : 'Geral';
      final rawValue = (valueIdx >= 0 && valueIdx < row.length) ? row[valueIdx].toString().trim() : '0';
      final notes = (notesIdx >= 0 && notesIdx < row.length) ? row[notesIdx].toString().trim() : null;

      final parsedValue = double.tryParse(rawValue.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

      validLeads.add(LeadModel(
        id: '', // Será gerado pelo banco
        name: name,
        phone: PhoneUtils.formatDisplay(rawPhone),
        city: city,
        state: state,
        interest: interest,
        propertyValue: parsedValue,
        source: defaultSource,
        notes: notes,
        status: LeadStatus.novo,
      ));
    }

    return ImportPreviewResult(
      totalRows: rows.length - 1,
      validLeads: validLeads,
      invalidRows: invalidRows,
      duplicatePhones: duplicatePhones,
    );
  }

  /// Insere os leads validados no banco de dados na fila central
  Future<int> commitImport(List<LeadModel> leads) async {
    if (leads.isEmpty) return 0;

    final rowsToInsert = leads.map((l) {
      return {
        'name': l.name,
        'phone': l.phone,
        'city': l.city,
        'state': l.state,
        'interest': l.interest,
        'property_value': l.propertyValue,
        'source': l.source,
        'notes': l.notes,
        'status': 'NOVO',
        'priority': 'normal',
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    // Insere em lotes de 100
    const chunkSize = 100;
    int insertedCount = 0;

    for (var i = 0; i < rowsToInsert.length; i += chunkSize) {
      final chunk = rowsToInsert.sublist(
        i,
        i + chunkSize > rowsToInsert.length ? rowsToInsert.length : i + chunkSize,
      );

      final response = await _supabase.from('leads').insert(chunk).select('id');
      insertedCount += (response as List).length;
    }

    await _auditService.log(
      action: 'LEADS_IMPORTED',
      entityType: 'lead_import',
      notes: '$insertedCount leads importados com sucesso para a fila central',
    );

    return insertedCount;
  }
}
