import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:llm_ui/chat.dart';
import 'package:llm_ui/main.dart';

void main() {
  group('isTextAttachmentName', () {
    test('txt 及常见文本格式识别', () {
      expect(isTextAttachmentName('notes.txt'), isTrue);
      expect(isTextAttachmentName('readme.md'), isTrue);
      expect(isTextAttachmentName('data.json'), isTrue);
      expect(isTextAttachmentName('app.py'), isTrue);
      expect(isTextAttachmentName('x.YAML'), isTrue); // 忽略大小写
      expect(isTextAttachmentName('file.log'), isTrue);
    });

    test('非文本文件与无扩展名不识别', () {
      expect(isTextAttachmentName('photo.png'), isFalse);
      expect(isTextAttachmentName('doc.pdf'), isFalse);
      expect(isTextAttachmentName('archive.zip'), isFalse);
      expect(isTextAttachmentName('noextension'), isFalse);
      expect(isTextAttachmentName('.gitignore'), isFalse);
    });
  });

  group('formatFileSize', () {
    test('B / KB / MB / GB', () {
      expect(formatFileSize(512), '512 B');
      expect(formatFileSize(2048), '2.0 KB');
      expect(formatFileSize(1536), '1.5 KB');
      expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
      expect(formatFileSize(2 * 1024 * 1024 * 1024), '2.0 GB');
      expect(formatFileSize(null), '');
      expect(formatFileSize(0), '');
    });
  });

  group('MessageFilePart', () {
    test('modelContent 按 llama.cpp 风格拼接文件内容', () {
      final m = Message(
        role: Role.user,
        content: '总结一下',
        ts: DateTime.now(),
      )..fileParts = [
        MessageFilePart(name: 'notes.txt', size: 10, content: 'hello world'),
      ];
      expect(
        m.modelContent,
        'File: notes.txt\nContent:\nhello world\n\n总结一下',
      );
    });

    test('仅文件无正文时不产生多余空行', () {
      final m = Message(
        role: Role.user,
        content: '',
        ts: DateTime.now(),
      )..fileParts = [
        MessageFilePart(name: 'a.txt', size: 3, content: 'abc'),
      ];
      expect(m.modelContent, 'File: a.txt\nContent:\nabc');
    });

    test('无文件部件时 modelContent 即 content', () {
      final m = Message(role: Role.user, content: 'hi', ts: DateTime.now());
      expect(m.modelContent, 'hi');
    });

    test('toJson/fromJson 往返保留文件部件', () {
      final m = Message(
        role: Role.user,
        content: 'x',
        ts: DateTime.now(),
      )..fileParts = [
        MessageFilePart(
          name: 'big.txt',
          size: 2000000,
          content: 'data',
          truncated: true,
        ),
      ];
      final restored = Message.fromJson(jsonDecode(jsonEncode(m.toJson())));
      expect(restored.fileParts, hasLength(1));
      expect(restored.fileParts!.first.name, 'big.txt');
      expect(restored.fileParts!.first.size, 2000000);
      expect(restored.fileParts!.first.truncated, isTrue);
      expect(restored.fileParts!.first.content, 'data');
    });
  });
}
