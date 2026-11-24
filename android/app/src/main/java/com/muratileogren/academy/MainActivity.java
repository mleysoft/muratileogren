package com.muratileogren.academy;

import android.app.NotificationManager;
import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String BADGE_CHANNEL = "muratileogren/notification_badge";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BADGE_CHANNEL)
      .setMethodCallHandler((call, result) -> {
        if (!"setBadge".equals(call.method)) {
          result.notImplemented();
          return;
        }
        Integer count = call.argument("count");
        // Android launcher badges are derived from active notifications.
        // Once every item is read, remove this app's old notifications so
        // launchers no longer display the stale red dot/count.
        if (count != null && count <= 0) {
          NotificationManager nm =
            (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
          if (nm != null) nm.cancelAll();
        }
        result.success(null);
      });
  }
}
