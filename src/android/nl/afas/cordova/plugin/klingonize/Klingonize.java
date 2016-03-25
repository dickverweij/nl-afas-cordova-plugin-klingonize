/*
The MIT License (MIT)

Copyright (c) 2016 Dick Verweij dickydick1969@hotmail.com, d.verweij@afas.nl

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package nl.afas.cordova.plugin.klingonize;

import org.apache.cordova.PluginResult;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;

import android.graphics.Paint;
import android.graphics.Rect;
import android.util.Base64;
import android.util.SparseArray;

import com.google.android.gms.vision.Frame;
import com.google.android.gms.vision.face.FaceDetector;
import com.google.android.gms.vision.face.Face;
import com.google.android.gms.vision.face.Landmark;

import java.io.ByteArrayOutputStream;

import nl.afas.pocket2.R;

public class Klingonize extends CordovaPlugin {

    @Override
    public boolean execute(final String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        String result = null;

		if (args.length() == 2 && args.getString(1).length() > 0) {
			String mimetype = args.getString(0);
			String imageBase64 = args.getString(1);

			byte[] decodedString = Base64.decode(imageBase64, Base64.DEFAULT);
			Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);

			FaceDetector detector = new FaceDetector.Builder( this.cordova.getActivity().getApplicationContext())
					.setTrackingEnabled(false)
					.setLandmarkType(FaceDetector.ALL_LANDMARKS)
					.setProminentFaceOnly(true)
					.setMode(FaceDetector.FAST_MODE)
					.build();

			if (!detector.isOperational()) {
				//Handle contingency
			} else {
				Frame frame = new Frame.Builder().setBitmap(decodedByte).build();
				SparseArray<Face> faces = detector.detect(frame);
				detector.release();

				if (faces.size() == 1){
					Face face = faces.valueAt(0);

					if (face.getLandmarks().size()>5) {
						Bitmap bm = BitmapFactory.decodeResource(this.cordova.getActivity().getResources(), R.drawable.klingonface);

						Bitmap bmOverlay = Bitmap.createBitmap(decodedByte.getWidth(), decodedByte.getHeight(), decodedByte.getConfig());
						Rect srcRect = new Rect(0, 0, bm.getWidth(), bm.getHeight());

						Rect faceRect = new Rect((int)face.getPosition().x,(int)face.getPosition().y,(int)(face.getPosition().x + face.getWidth()), (int)(face.getPosition().y + face.getHeight()));

						faceRect.inset((int)(face.getLandmarks().get(Landmark.LEFT_EYE).getPosition().x - face.getPosition().x) ,(int)(face.getLandmarks().get(Landmark.LEFT_EYE).getPosition().y - face.getPosition().y));

						double sx = (double) faceRect.width() / 163.0;
						double sy = (double) faceRect.height() / 183.0;
						double ssx = sx * 552.0;
						double ssy = sy * 634.0;

						double ox = (double) faceRect.left - ssx;
						double oy = (double) faceRect.top - ssy;

						Rect destRect = new Rect((int) ox, (int) oy, (int) (ox + (double) bm.getWidth() * sx), (int) (oy+ (double) bm.getHeight() * sy));

						Canvas canvas = new Canvas(bmOverlay);
						canvas.drawBitmap(decodedByte, new Matrix(), null);

						canvas.drawBitmap(bm, srcRect, destRect, null);

						ByteArrayOutputStream baos = new ByteArrayOutputStream();
						bmOverlay.compress(Bitmap.CompressFormat.JPEG, 100, baos);
						byte[] b = baos.toByteArray();
						result = Base64.encodeToString(b, Base64.DEFAULT);
					}
				}
			}

		}

		PluginResult pluginResult;

		if (result != null) {
			pluginResult = new PluginResult(PluginResult.Status.OK, result);
		}
		else {
			pluginResult = new PluginResult(PluginResult.Status.ERROR);
		}        
        callbackContext.sendPluginResult(pluginResult);

        return true;
    }

  
}


























