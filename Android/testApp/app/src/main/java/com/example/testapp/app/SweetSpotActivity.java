package com.example.testapp.app;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.TextView;


public class SweetSpotActivity extends Activity {

    int score = 0;
    TextView textScore;
    private Handler scoreHandler = new Handler();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sweet_spot);
        Log.d("onCreate", "grabbing TextView");
        textScore = (TextView)findViewById(R.id.scoreCount);
    }

    @Override
    protected void onResume(){
        super.onResume();
        GrabScore();
    }

    private void GrabScore(){
        scoreHandler.postDelayed(ScoreViewChanger, 1000);
    }
    private void StopScore(){
        scoreHandler.removeCallbacks(ScoreViewChanger);
    }

    private Runnable ScoreViewChanger = new Runnable() {
        @Override
        public void run() {
            textScore.setText(score + "");
            score += 5;
            GrabScore();
        }
    };


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.sweet_spot, menu);
        return true;
    }

    @Override
    protected void onPause(){
        super.onPause();
        StopScore();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == android.R.id.home) {
            StopScore();
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

}
