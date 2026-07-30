// TextSpan parseMarkdown(String text) {
//   final spans = <TextSpan>[];
//
//   final boldRegex = RegExp(r'\*\*(.*?)\*\*');
//
//   text.splitMapJoin(
//     boldRegex,
//     onMatch: (m) {
//       spans.add(
//         TextSpan(
//           text: m.group(1),
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//       );
//       return '';
//     },
//     onNonMatch: (text) {
//       spans.add(TextSpan(text: text));
//       return '';
//     },
//   );
//
//   return TextSpan(children: spans);
// }
