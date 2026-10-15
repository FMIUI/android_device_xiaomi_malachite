/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.refreshrate;

import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.provider.Settings;
import android.util.Log;

/**
 * The panel drivers expose a 30 Hz mode that is meant for MIUI's AOD. With no minimum
 * refresh rate set, DisplayModeDirector lets SurfaceFlinger drop to it whenever the
 * screen is idle, which flickers and holds the brightness down. Android has no
 * resource for the default minimum, so set it here, once, per user. A value the user
 * chose in Settings is left alone.
 */
public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "MalachiteRefreshRate";

    // Settings.System.MIN_REFRESH_RATE
    private static final String MIN_REFRESH_RATE = "min_refresh_rate";
    private static final float DEFAULT_MIN_REFRESH_RATE = 60f;

    @Override
    public void onReceive(Context context, Intent intent) {
        final String action = intent.getAction();
        if (!Intent.ACTION_LOCKED_BOOT_COMPLETED.equals(action)
                && !Intent.ACTION_BOOT_COMPLETED.equals(action)) {
            return;
        }

        final ContentResolver resolver = context.getContentResolver();
        if (Settings.System.getString(resolver, MIN_REFRESH_RATE) != null) {
            return;
        }
        try {
            Settings.System.putFloat(resolver, MIN_REFRESH_RATE, DEFAULT_MIN_REFRESH_RATE);
        } catch (RuntimeException e) {
            Log.e(TAG, "Failed to set " + MIN_REFRESH_RATE, e);
        }
    }
}
