// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/longevo_model.dart';

class DocumentsScreen extends StatefulWidget {
  final LongevoVinculo vinculo;

  const DocumentsScreen({super.key, required this.vinculo});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List> _docsFuture;

  @override
  void initState() {
    super.initState();
    _docsFuture = _fetchDocumentos();
  }

  Future<List> _fetchDocumentos() async {
    final response = await _supabase
        .from('documento_longevo')
        .select('*')
        .eq('id_longevo', widget.vinculo.idLongevo)
        .order('enviado_em', ascending: false);

    return List.from(response);
  }

  Future<void> _abrirArquivo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _excluirDocumento(int idDocumento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Documento'),
        content: const Text('Deseja remover este laudo/carteirinha?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await _supabase
        .from('documento_longevo')
        .delete()
        .eq('id_documento', idDocumento);

    if (mounted) {
      setState(() => _docsFuture = _fetchDocumentos());
    }
  }

  void _abrirModalUpload() {
    final tituloCtrl = TextEditingController();
    String tipoSelecionado = 'laudo_pdf';
    Uint8List? arquivoBytes;
    String? nomeArquivo;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void selecionarArquivoWeb() {
              final input = html.FileUploadInputElement()
                ..accept = '.pdf,image/*';
              input.click();

              input.onChange.listen((event) {
                final files = input.files;
                if (files != null && files.isNotEmpty) {
                  final file = files.first;
                  final reader = html.FileReader();
                  reader.readAsArrayBuffer(file);
                  reader.onLoadEnd.listen((_) {
                    final result = reader.result;
                    Uint8List? bytes;
                    if (result is Uint8List) {
                      bytes = result;
                    } else if (result is ByteBuffer) {
                      bytes = result.asUint8List();
                    }

                    setModalState(() {
                      arquivoBytes = bytes;
                      nomeArquivo = file.name;
                    });
                  });
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Adicionar Documento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: tipoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Documento',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'laudo_pdf',
                        child: Text('Laudo Médico / Receita (PDF)'),
                      ),
                      DropdownMenuItem(
                        value: 'carteirinha',
                        child: Text('Carteirinha (Convênio / SUS / RG)'),
                      ),
                      DropdownMenuItem(
                        value: 'exame',
                        child: Text('Resultado de Exame'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => tipoSelecionado = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título / Identificação *',
                      hintText: 'Ex: Carteirinha Unimed ou Laudo Cardiologista',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: selecionarArquivoWeb,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      nomeArquivo ?? 'Selecionar PDF ou Imagem',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () async {
                              if (tituloCtrl.text.trim().isEmpty ||
                                  arquivoBytes == null ||
                                  nomeArquivo == null) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Preencha o título e selecione um arquivo.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isUploading = true);

                              try {
                                final url =
                                    await StorageService.uploadDocumentoBytes(
                                  bytes: arquivoBytes!,
                                  nomeOriginal: nomeArquivo!,
                                  pasta: 'documentos',
                                  identificador:
                                      'doc_${widget.vinculo.idLongevo}',
                                );

                                if (url == null) {
                                  throw Exception('Falha ao gerar URL pública.');
                                }

                                await _supabase
                                    .from('documento_longevo')
                                    .insert({
                                  'id_longevo': widget.vinculo.idLongevo,
                                  'titulo': tituloCtrl.text.trim(),
                                  'tipo': tipoSelecionado,
                                  'arquivo_url': url,
                                });

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);

                                if (!mounted) return;
                                setState(() {
                                  _docsFuture = _fetchDocumentos();
                                });
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Documento enviado com sucesso!'),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isUploading = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao enviar: $e'),
                                    backgroundColor: AppTheme.danger,
                                  ),
                                );
                              }
                            },
                      child: isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar Documento'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconePorTipo(String tipo) {
    switch (tipo) {
      case 'carteirinha':
        return Icons.badge_rounded;
      case 'exame':
        return Icons.biotech_rounded;
      default:
        return Icons.picture_as_pdf_rounded;
    }
  }

  String _labelPorTipo(String tipo) {
    switch (tipo) {
      case 'carteirinha':
        return 'Carteirinha';
      case 'exame':
        return 'Exame';
      default:
        return 'Laudo / Receita';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vinculo.apelidoLongevo,
              style: const TextStyle(fontSize: 14),
            ),
            const Text(
              'Laudos e Carteirinhas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.vinculo.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _abrirModalUpload,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Enviar Arquivo'),
            )
          : null,
      body: FutureBuilder<List>(
        future: _docsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum laudo ou carteirinha cadastrado.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final tipo = doc['tipo'] as String? ?? 'laudo_pdf';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppTheme.line),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconePorTipo(tipo),
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    doc['titulo'] ?? 'Documento',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                  subtitle: Text(
                    '${_labelPorTipo(tipo)} • Toque para abrir',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.vinculo.isAdmin)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.danger,
                          ),
                          tooltip: 'Remover documento',
                          onPressed: () =>
                              _excluirDocumento(doc['id_documento'] as int),
                        ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  onTap: () => _abrirArquivo(doc['arquivo_url'] as String),
                ),
              );
            },
          );
        },
      ),
    );
  }
}