import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;
  static const String _bucketName = 'longevus-arquivos';
  static final _picker = ImagePicker();

  /// Abre o seletor de imagens (funciona direto no Chrome e no Celular)
  static Future<XFile?> selecionarImagem() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  /// Faz o upload da imagem e retorna a URL pública
  static Future<String?> uploadImagem({
    required XFile arquivo,
    required String pasta,
    required String identificador,
  }) async {
    final Uint8List bytes = await arquivo.readAsBytes();

    final nome = arquivo.name;
    final extensao = nome.contains('.') ? nome.split('.').last : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final caminhoArquivo = '$pasta/${identificador}_$timestamp.$extensao';

    await _supabase.storage.from(_bucketName).uploadBinary(
          caminhoArquivo,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extensao',
            upsert: true,
          ),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(caminhoArquivo);
  }
}