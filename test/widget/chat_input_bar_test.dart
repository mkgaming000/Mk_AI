import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/features/chat/presentation/widgets/chat_input_bar.dart';

void main() {
  group('ChatInputBar', () {
    testWidgets('renders the send button when not streaming',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              isStreaming: false,
              onSend: (_, __) {},
              onStop: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
    });

    testWidgets('renders the stop button when streaming', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              isStreaming: true,
              onSend: (_, __) {},
              onStop: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    });

    testWidgets('calls onSend with the typed text when the send button '
        'is tapped', (tester) async {
      String? sentContent;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              isStreaming: false,
              onSend: (content, _) => sentContent = content,
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Hello AI');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(sentContent, 'Hello AI');
    });

    testWidgets('does not call onSend when the input is empty',
        (tester) async {
      bool sendCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              isStreaming: false,
              onSend: (_, __) => sendCalled = true,
              onStop: () {},
            ),
          ),
        ),
      );

      // With no text entered, the send button should not trigger onSend.
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(sendCalled, false);
    });

    testWidgets('clears the text field after a successful send',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              isStreaming: false,
              onSend: (_, __) {},
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Test message');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('calls onStop when the stop button is tapped',
        (tester) async {
      bool stopped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              isStreaming: true,
              onSend: (_, __) {},
              onStop: () => stopped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      expect(stopped, true);
    });
  });
}
