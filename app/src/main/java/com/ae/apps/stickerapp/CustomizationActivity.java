package com.ae.apps.stickerapp;

import android.graphics.Color;
import android.os.Bundle;
import android.widget.FrameLayout;
import android.widget.Spinner;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import androidx.appcompat.app.AppCompatActivity;

public class CustomizationActivity extends AppCompatActivity {

    private FrameLayout customizationCanvas;
    private Spinner textAnimationSpinner;
    private Spinner borderAnimationSpinner;
    private EditText gifSearchInput;
    private Button searchGifButton;
    private RequestQueue requestQueue;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_customization);

        customizationCanvas = findViewById(R.id.customization_canvas);
        textAnimationSpinner = findViewById(R.id.text_animation_spinner);
        borderAnimationSpinner = findViewById(R.id.border_animation_spinner);
        gifSearchInput = findViewById(R.id.gif_search_input);
        searchGifButton = findViewById(R.id.search_gif_button);
        requestQueue = Volley.newRequestQueue(this);

        // Set up spinners with animation options
        setupSpinners();

        // Set default canvas background to transparent
        customizationCanvas.setBackgroundColor(Color.TRANSPARENT);

        // Set up GIF search button
        searchGifButton.setOnClickListener(v -> searchGif(gifSearchInput.getText().toString()));
    }

    private void setupSpinners() {
        // Example animation options
        String[] textAnimations = {"Fade In", "Slide Up", "Zoom In", "Rotate", "Bounce"};
        String[] borderAnimations = {"Pulse", "Glow", "Dash", "Expand", "Shrink"};

        ArrayAdapter<String> textAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, textAnimations);
        textAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        textAnimationSpinner.setAdapter(textAdapter);

        ArrayAdapter<String> borderAdapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, borderAnimations);
        borderAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        borderAnimationSpinner.setAdapter(borderAdapter);
    }

    private void searchGif(String query) {
        String apiKey = "LIVDSRZULELA"; // Replace with your Tenor API key
        String url = "https://g.tenor.com/v1/search?q=" + query + "&key=" + apiKey + "&limit=20";

        JsonObjectRequest jsonObjectRequest = new JsonObjectRequest(Request.Method.GET, url, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        try {
                            JSONArray results = response.getJSONArray("results");
                            if (results.length() > 0) {
                                JSONObject gifObject = results.getJSONObject(0);
                                String gifUrl = gifObject.getJSONArray("media").getJSONObject(0).getJSONObject("gif").getString("url");
                                displayGif(gifUrl);
                            } else {
                                Toast.makeText(CustomizationActivity.this, "No GIFs found", Toast.LENGTH_SHORT).show();
                            }
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Toast.makeText(CustomizationActivity.this, "Error fetching GIFs", Toast.LENGTH_SHORT).show();
            }
        });

        requestQueue.add(jsonObjectRequest);
    }

    private void displayGif(String gifUrl) {
        // Logic to display GIF on the canvas
        Toast.makeText(this, "GIF URL: " + gifUrl, Toast.LENGTH_SHORT).show();
        // You can use libraries like Glide or Fresco to load the GIF into an ImageView
    }
}