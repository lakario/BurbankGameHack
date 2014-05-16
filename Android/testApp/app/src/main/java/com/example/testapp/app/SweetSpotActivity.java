package com.example.testapp.app;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationManager;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.RemoteException;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.TextView;
import android.widget.Toast;

import com.estimote.sdk.Beacon;
import com.estimote.sdk.BeaconManager;
import com.estimote.sdk.Region;
import com.estimote.sdk.Utils;
import com.estimote.sdk.utils.L;

import org.w3c.dom.Text;

import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;


public class SweetSpotActivity extends Activity {
    private static final String TAG = SweetSpotActivity.class.getSimpleName();
    private static final Region ALL_ESTIMOTE_BEACONS_REGION = new Region("rid", null, null, null);
    private static final int REQUEST_ENABLE_BT = 1234;
    static int score = 0;
    static int count = 0;

    // needs to be nullable
    static double distance = 0;
    static int modifier = 0;
    TextView textScore;
    TextView beaconCount;
    TextView inRange;
    TextView distanceText;
    private Handler scoreHandler = new Handler();
    private BeaconManager beaconManager;
    private Beacon beacon;
    private Region region;
    private boolean inRegion = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        L.enableDebugLogging(true);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sweet_spot);
        Log.d("onCreate", "grabbing TextView");
        textScore = (TextView)findViewById(R.id.scoreCount);
        beaconCount = (TextView)findViewById(R.id.beaconCount);
        inRange = (TextView)findViewById(R.id.inRange);
        distanceText = (TextView)findViewById(R.id.distance);
        beaconManager = new BeaconManager(this);
        beaconManager.setBackgroundScanPeriod(TimeUnit.SECONDS.toMillis(1), 0);
        beaconManager.setRangingListener(new BeaconManager.RangingListener() {
            @Override
            public void onBeaconsDiscovered(Region reg, final List<Beacon> beacons) {
                if (beacon == null && beacons.size() > 0) {
                    Log.d("BeaconDiscovered", "Grabbing Beacon");
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            count = beacons.size();
                            beaconCount.setText("Beacons: " + count);
                            Random random = new Random();
                            beacon = beacons.get((count>0)?random.nextInt(count):0);
                            region = new Region("regionId", beacon.getProximityUUID(), beacon.getMajor(), beacon.getMinor());
                            try {
                                beaconManager.startMonitoring(region);
                            } catch (RemoteException e) {
                                Log.d(TAG, "Error while starting monitoring!");
                            }
                            if(distance <= 3){
                                modifier = 1;
                                textScore.setTextColor(Color.GREEN);
                            }else if(distance > 3 || distance <= 5){
                                modifier = 0;
                                textScore.setTextColor(Color.BLACK);
                            }else{
                                modifier = -1;
                                textScore.setTextColor(Color.RED);
                            }
                            distanceText.setText("Distance: " + distance);
                            inRegion = true;
                            inRange.setText("In Range");
                            GrabScore();
                        }
                    });

                }
            }
        });
        Log.d("Monitoring", "Adding Monitoring");
        beaconManager.setMonitoringListener(new BeaconManager.MonitoringListener() {
            @Override
            public void onEnteredRegion(Region region, List<Beacon> beacons) {
                inRegion = true;
                inRange.setText("In Range");
                distance = Utils.computeAccuracy(beacon);
                distanceText.setText("Distance: " + distance);
            }

            @Override
            public void onExitedRegion(Region region) {
                inRegion = false;
                inRange.setText("Not In Range");
                distanceText.setText("Distance: unknown");
            }
        });
    }

    @Override
    protected void onResume(){
        super.onResume();
        if(region != null) {
            beaconManager.connect(new BeaconManager.ServiceReadyCallback() {
                @Override
                public void onServiceReady() {
                    try {
                        beaconManager.startMonitoring(region);
                    } catch (RemoteException e) {
                        Log.d(TAG, "Error while starting monitoring!");
                    }
                }
            });
            GrabScore();
        }
    }

    private void GrabScore(){
        scoreHandler.postDelayed(ScoreViewChanger, 200);
    }
    private void StopScore(){
        scoreHandler.removeCallbacks(ScoreViewChanger);
    }

    private Runnable ScoreViewChanger = new Runnable() {
        @Override
        public void run() {
            if(inRegion) {
                if(distance <= 3){
                    modifier = 1;
                    textScore.setTextColor(Color.GREEN);
                }else if(distance > 3 || distance <= 5){
                    modifier = 0;
                    textScore.setTextColor(Color.BLACK);
                }else{
                    modifier = -1;
                    textScore.setTextColor(Color.RED);
                }
                textScore.setText(score + "");
                score += (1 * modifier);
                GrabScore();
            }
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
    protected void onStart(){
        super.onStart();

        // Check if device supports Bluetooth Low Energy.
        if(!beaconManager.hasBluetooth()){
            Toast.makeText(this, "Device does not have Bluetooth Low Energy", Toast.LENGTH_LONG).show();
            return;
        }

        // If Bluetooth is not enabled, let user enable it.
        if(!beaconManager.isBluetoothEnabled()){
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        }else{
            connectToService();
        }

        textScore.setText(score + "");
        beaconCount.setText("Beacons: " + count);
        inRange.setText(((!inRegion)?"Not ":"") + "In Range");

        distanceText.setText("Distance: " + ((!inRegion)?"unknown":distance));
    }

    private void connectToService(){
        getActionBar().setSubtitle("Scanning...");
        beaconManager.connect(new BeaconManager.ServiceReadyCallback(){
            @Override
            public void onServiceReady(){
                try{
                    beaconManager.startRanging(ALL_ESTIMOTE_BEACONS_REGION);
                }catch (RemoteException e){
                    Toast.makeText(SweetSpotActivity.this, "Cannot start ranging, something terrible happened", Toast.LENGTH_LONG).show();
                    Log.e(TAG, "Cannot start ranging", e);
                }
            }
        });
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
