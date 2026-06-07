// import 'package:astrologer_app/features/service/ChatScreen.dart';
// import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class ChatMiniBanner extends StatefulWidget {
//   final ChatMinimizeProvider provider;
//   const ChatMiniBanner({required this.provider});
//   @override
//   State<ChatMiniBanner> createState() => ChatMiniBannerState();
// }

// class ChatMiniBannerState extends State<ChatMiniBanner>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<Offset>   _slide;
//   bool _confirmEnd = false;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl  = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 350));
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end  : Offset.zero,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
//     _ctrl.forward();
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   void _tapResume() {
//     final mini = context.read<ChatMinimizeProvider>();
//     mini.resume();
//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (_) => ChatScreen(
//         channelId : mini.channelId,
//         astroId   : mini.astroId,
//         userId    : mini.userId,
//         userName  : mini.userName,
//         userAvatar: mini.userAvatar,
//       ),
//     ));
//   }

//   void _tapEnd() {
//     if (!_confirmEnd) {
//       setState(() => _confirmEnd = true);
//       Future.delayed(const Duration(seconds: 4), () {
//         if (mounted) setState(() => _confirmEnd = false);
//       });
//     } else {
//       context.read<ChatMinimizeProvider>().endAndClear();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mini  = context.watch<ChatMinimizeProvider>();
//     final safeB = MediaQuery.of(context).padding.bottom;

//     return SlideTransition(
//       position: _slide,
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           margin: EdgeInsets.only(left: 10, right: 10, bottom: safeB + 10),
//           height: 68,
//           decoration: BoxDecoration(
//             color       : const Color(0xFF1C1C1E),
//             borderRadius: BorderRadius.circular(20),
//             boxShadow   : [
//               BoxShadow(
//                 color    : Colors.black.withOpacity(0.40),
//                 blurRadius: 20,
//                 offset   : const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Row(children: [
//             const SizedBox(width: 12),

//             // Avatar + green dot
//             Stack(clipBehavior: Clip.none, children: [
//               CircleAvatar(
//                 radius         : 22,
//                 backgroundColor: Colors.grey.shade700,
//                 backgroundImage: mini.userAvatar.isNotEmpty
//                     ? NetworkImage(mini.userAvatar)
//                     : null,
//                 child: mini.userAvatar.isEmpty
//                     ? const Icon(Icons.person, color: Colors.white)
//                     : null,
//               ),
//               Positioned(
//                 bottom: 0, right: 0,
//                 child: Container(
//                   width : 12, height: 12,
//                   decoration: BoxDecoration(
//                     color : Colors.greenAccent.shade400,
//                     shape : BoxShape.circle,
//                     border: Border.all(color: const Color(0xFF1C1C1E), width: 2),
//                   ),
//                 ),
//               ),
//             ]),

//             const SizedBox(width: 10),

//             // Name + timer
//             Expanded(
//               child: Column(
//                 mainAxisAlignment : MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     mini.userName,
//                     style: const TextStyle(
//                       color     : Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize  : 14,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Row(children: [
//                     Container(
//                       width : 7, height: 7,
//                       decoration: const BoxDecoration(
//                           color: Colors.greenAccent, shape: BoxShape.circle),
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       'Chat  ${mini.formattedTime}',
//                       style: const TextStyle(
//                         color     : Color(0xFFFFD600),
//                         fontSize  : 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ]),
//                 ],
//               ),
//             ),

//             // Resume
//             GestureDetector(
//               onTap: _tapResume,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                 decoration: BoxDecoration(
//                   color       : const Color(0xFFFFD600),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Text('Resume',
//                     style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13)),
//               ),
//             ),

//             const SizedBox(width: 8),

//             // End (two-tap confirm)
//             GestureDetector(
//               onTap: _tapEnd,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color       : _confirmEnd
//                       ? Colors.red
//                       : Colors.red.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(20),
//                   border      : Border.all(color: Colors.red.shade400, width: 1),
//                 ),
//                 child: Text(
//                   _confirmEnd ? 'Confirm?' : 'End',
//                   style: TextStyle(
//                     color     : _confirmEnd ? Colors.white : Colors.red.shade300,
//                     fontWeight: FontWeight.bold,
//                     fontSize  : 13,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 12),
//           ]),
//         ),
//       ),
//     );
//   }
// }