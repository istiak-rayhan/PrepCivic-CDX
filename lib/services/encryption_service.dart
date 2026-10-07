/// Legacy compatibility helper. The bundled question assets are plaintext.
/// This method does not encrypt or decrypt data.
class EncryptionService {
  static String decryptData(String text) => text;
}
