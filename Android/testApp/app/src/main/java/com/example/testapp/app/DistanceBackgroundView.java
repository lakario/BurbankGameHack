package com.example.testapp.app;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.View;

/**
 * Created by raponte on 5/3/2014.
 */
public class DistanceBackgroundView extends View {
    private final Drawable drawable;

    public DistanceBackgroundView(Context context, AttributeSet attrs){
        super(context, attrs);
        drawable = context.getResources().getDrawable(R.drawable.bg_distance);
    }

    @Override
    public void onDraw(Canvas canvas){
        super.onDraw(canvas);

        int width = drawable.getIntrinsicWidth() * canvas.getHeight() / drawable.getIntrinsicHeight();
        int deltaX = (width - canvas.getHeight()) / 2;
        drawable.setBounds(-deltaX, 0, width - deltaX, canvas.getHeight());
        drawable.draw(canvas);
    }
}
