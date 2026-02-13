import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_salon/services/validation_service.dart';

void main() {
  group('ValidationService - Email Validation', () {
    test('should return true for valid email', () {
      expect(ValidationService.isValidEmail('test@example.com'), true);
      expect(ValidationService.isValidEmail('user.name@domain.co'), true);
    });

    test('should return false for invalid email', () {
      expect(ValidationService.isValidEmail(''), false);
      expect(ValidationService.isValidEmail('invalid'), false);
      expect(ValidationService.isValidEmail('test@'), false);
      expect(ValidationService.isValidEmail('test@domain'), false);
    });
  });

  group('ValidationService - Password Validation', () {
    test('should return true for valid password', () {
      expect(ValidationService.isValidPassword('Password123'), true);
      expect(ValidationService.isValidPassword('Test123456'), true);
    });

    test('should return false for invalid password', () {
      expect(ValidationService.isValidPassword(''), false);
      expect(ValidationService.isValidPassword('short'), false);
      expect(ValidationService.isValidPassword('nouppercase123'), false);
      expect(ValidationService.isValidPassword('NODIGITS'), false);
    });
  });

  group('ValidationService - Note Title Validation', () {
    test('should return true for valid note title', () {
      expect(ValidationService.isValidNoteTitle('My Note'), true);
    });

    test('should return false for invalid note title', () {
      expect(ValidationService.isValidNoteTitle(''), false);
      expect(ValidationService.isValidNoteTitle('A' * 101), false);
    });
  });

  // Исправленный тест для edge cases
  test('should handle edge cases', () {
    // Вместо передачи null, проверяем поведение с пустыми строками
    expect(ValidationService.isValidEmail(''), false);
    expect(ValidationService.isValidPassword(''), false);
    expect(ValidationService.isValidNoteTitle(''), false);
  });
}