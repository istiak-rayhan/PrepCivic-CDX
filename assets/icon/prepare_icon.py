from rembg import remove
from PIL import Image
import io

def prepare_app_icon(input_path, output_path):
    # 1. Load the image
    with open(input_path, 'rb') as i:
        input_data = i.read()
    
    # 2. Remove background using rembg (highly accurate for this type of distinct logo)
    print("Removing background...")
    subject = remove(input_data)
    img = Image.open(io.BytesIO(subject)).convert("RGBA")
    
    # 3. Create a 1024x1024 canvas (Standard App Store/Play Store Master Size)
    canvas_size = (1024, 1024)
    canvas = Image.new("RGBA", canvas_size, (255, 255, 255, 0)) # Transparent background
    
    # 4. Resize the logo to fit within the "Safe Zone"
    # Adaptive icons usually crop the outer ~30%. 
    # We'll scale the logo to be about 65% of the total canvas size to be safe.
    target_scale = 0.65
    
    aspect_ratio = img.width / img.height
    new_width = int(canvas_size[0] * target_scale)
    new_height = int(new_width / aspect_ratio)
    
    img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # 5. Center the image on the canvas
    x_offset = (canvas_size[0] - new_width) // 2
    y_offset = (canvas_size[1] - new_height) // 2
    
    canvas.paste(img_resized, (x_offset, y_offset), img_resized)
    
    # 6. Save
    canvas.save(output_path, format="PNG")
    print(f"Success! Saved prepared icon to {output_path}")

if __name__ == "__main__":
    prepare_app_icon("logo.jpg", "icon_master.png")