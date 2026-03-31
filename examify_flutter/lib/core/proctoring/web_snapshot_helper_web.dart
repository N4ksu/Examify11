import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class WebSnapshotHelper {
  static Future<dynamic> getScreenStream() async {
    try {
      final mediaDevices = web.window.navigator.mediaDevices;
      
      final options = {'video': {'cursor': 'always'}, 'audio': false}.jsify() as web.DisplayMediaStreamOptions;
      return await mediaDevices.getDisplayMedia(options).toDart;
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> createVideoElement(dynamic stream) async {
    if (stream == null) return null;
    final video = web.HTMLVideoElement()
      ..srcObject = stream as web.MediaStream
      ..autoplay = true
      ..muted = true;
      
    final completer = Completer<void>();
    video.addEventListener('loadedmetadata', ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS);
    
    await completer.future;
    return video;
  }

  static Future<String?> captureFrame(dynamic screenVideo) async {
    if (screenVideo == null) return null;
    final video = screenVideo as web.HTMLVideoElement;
    
    // Canvas dimensions should match video resolution
    final canvas = web.HTMLCanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    context.drawImage(video, 0, 0);
    
    // Quality 0.25 (25%) as requested
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.25);
    return dataUrl.substring(dataUrl.indexOf(',') + 1);
  }

  static void stopStream(dynamic stream) {
    if (stream != null) {
      final mediaStream = stream as web.MediaStream;
      final tracks = mediaStream.getTracks().toDart;
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        track.stop();
      }
    }
  }
}
