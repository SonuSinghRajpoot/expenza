# Font Files Required

To properly display the rupee symbol (₹) in PDF exports, please download and place the following Roboto font files in this directory:

1. **Roboto-Regular.ttf** - Regular weight font
2. **Roboto-Bold.ttf** - Bold weight font

## Download Links

You can download these fonts from:
- Google Fonts: https://fonts.google.com/specimen/Roboto
- Direct download: https://github.com/google/fonts/tree/main/apache/roboto

Or use these direct links:
- Roboto Regular: https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf
- Roboto Bold: https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf

## Instructions

1. Download both font files
2. Place them in this `assets/fonts/` directory
3. Run `flutter pub get` to ensure assets are registered
4. The PDF export will automatically use these fonts to display the rupee symbol correctly

## Note

If the font files are not found, the PDF will fall back to default fonts and may display "Rs." instead of "₹" for currency amounts.
