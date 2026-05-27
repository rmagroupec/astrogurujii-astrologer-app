import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrologer_app/features/service/provider/VideoCallProvider.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String token;
  final String channelId;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.token,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with WidgetsBindingObserver {
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    /// 🔥 VERY IMPORTANT: init Agora AFTER route is stable
    Future.microtask(() async {
      final provider = Provider.of<VideoCallProvider>(context, listen: false);

      await provider.initAgora(
        channelId: widget.channelId,
        token: widget.token,
      );

      /// 💰 Start deduction (astrologer logic)
      provider.startDeduction(
        channelId: widget.channelId,
        deductApi: ApiService().deductAmount,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  final provider = Provider.of<VideoCallProvider>(context, listen: false);

  if (state == AppLifecycleState.paused) {
  provider.engine?.muteLocalVideoStream(true);
} else if (state == AppLifecycleState.resumed) {
  provider.engine?.muteLocalVideoStream(false);
}

}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoCallProvider>();



    return WillPopScope(
      onWillPop: () async {
        await provider.endLocalCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// ================= REMOTE VIDEO / PLACEHOLDER =================
            GestureDetector(
              onTap: () => setState(() => _showUI = !_showUI),
              child: SizedBox.expand(child: _remoteVideo(provider)),
            ),

            /// ================= LOCAL PIP VIDEO =================
            Positioned(
              top: 60,
              right: 16,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: provider.engine == null
                      ? const Center(
                          child: Text(
                            'ENGINE NULL',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: provider.engine!,
                            canvas: const VideoCanvas(uid: 0),
                            useFlutterTexture :true,
                          ),
                        ),
                ),
              ),
            ),

            /// ================= TOP INFO =================
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              child: AnimatedOpacity(
                opacity: _showUI ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                   Consumer<VideoCallProvider>(
  builder: (_, p, __) => Text(p.duration, style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),),
                   )

                     
                  
                  ],
                ),
              ),
            ),

            /// ================= BOTTOM CONTROLS =================
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _showUI ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 250),
                child: AnimatedOpacity(
                  opacity: _showUI ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _bottomControls(context, provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideo(VideoCallProvider provider) {
    if (provider.engine == null || provider.remoteUid == null) {
      return const Center(
        child: Text(
          'Waiting for user…',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

  return AgoraVideoView(
  controller: VideoViewController.remote(
    rtcEngine: provider.engine!,
    canvas: VideoCanvas(
      uid: provider.remoteUid!,
      // viewType: VideoViewType.texture, // 🔥 REQUIRED
    ),
    // useTextureView: true
    // useFlutterTexture :true,
    connection: RtcConnection(channelId: widget.channelId),
  ),
);

  }

  Widget _bottomControls(BuildContext context, VideoCallProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xAA000000),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
          icon: provider.speakerOn
              ? Icons.volume_up
              : Icons.hearing,
          label: 'Speaker',
         
          onTap: provider.toggleSpeaker,
        ),
          _controlButton(
            icon: provider.muted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            onTap: provider.toggleMute,
          ),
          _controlButton(
            icon: Icons.cameraswitch,
            label: 'Camera',
            onTap: provider.switchCamera,
          ),
          _controlButton(
            icon: provider.isVideoOn ? Icons.videocam : Icons.videocam_off,
            label: 'Video',
            onTap: provider.toggleVideo,
          ),
          _endCallButton(provider),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _endCallButton(VideoCallProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            await provider.endLocalCall();
            Navigator.pop(context);
          },
          child: const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red,
            child: Icon(Icons.call_end, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        const Text('End', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}
