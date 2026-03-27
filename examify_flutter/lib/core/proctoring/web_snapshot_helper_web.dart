import 'dart:async';
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class WebSnapshotHelper {
  static Future<dynamic> getScreenStream() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return null;
      
      return await (mediaDevices as dynamic).getDisplayMedia({
        'video': {'cursor': 'always'},
        'audio': false,
      });
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> createVideoElement(dynamic stream) async {
    if (stream == null) return null;
    final video = html.VideoElement()
      ..srcObject = stream as html.MediaStream
      ..autoplay = true
      ..muted = true;
      
    await video.onLoadedMetadata.first;
    return video;
  }

  static Future<String?> captureFrame(dynamic screenVideo) async {
    if (screenVideo == null) return null;
    final video = screenVideo as html.VideoElement;
    
    // Canvas dimensions should match video resolution
    final canvas = html.CanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    
    canvas.context2D.drawImage(video, 0, 0);
    
    // Quality 0.25 (25%) as requested
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.25);
    return dataUrl.substring(dataUrl.indexOf(',') + 1);
  }

  static void stopStream(dynamic stream) {
    if (stream != null && stream is html.MediaStream) {
      stream.getTracks().forEach((track) => track.stop());
    }
  }
}
