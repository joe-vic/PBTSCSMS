import 'package:flutter/material.dart';
// Remove GoogleFonts import completely
// // REMOVED: import 'package:google_fonts/google_fonts.dart';

/// School Management System Theme
/// Enhanced with Extended Color Options while maintaining all original properties
/// Now using LOCAL FONTS to prevent hanging issues
class SMSTheme {
  
  // =============================================================================
  // ORIGINAL COLOR PROPERTIES (ENHANCED WITH MORE OPTIONS)
  // =============================================================================
  
  /// Primary Colors (Your Original + Extended Options)
  static const Color primaryColor = Color(0xFFFFA725);        // YOUR Warm Orange - Main Brand
  static const Color secondaryColor = Color.fromARGB(255, 253, 182, 59);      // Warm Cream - Trust & Balance
  static const Color tertiaryColor = Color(0xFF43A047);       // Triadic Green - Growth & Success

  /// PRIMARY COLOR VARIATIONS (New Extended Options)
  /// Light variations of your primary orange
  static const Color primaryColor50 = Color(0xFFFFF8E1);     // Very light orange background
  static const Color primaryColor100 = Color(0xFFFFECB3);    // Light orange background
  static const Color primaryColor200 = Color(0xFFFFE082);    // Soft orange accent
  static const Color primaryColor300 = Color(0xFFFFD54F);    // Medium light orange
  static const Color primaryColor400 = Color(0xFFFFCA28);    // Medium orange
  static const Color primaryColor500 = Color(0xFFFFA725);    // YOUR PRIMARY (default)
  static const Color primaryColor600 = Color(0xFFFF8F00);    // Slightly darker orange
  static const Color primaryColor700 = Color(0xFFFF6F00);    // Dark orange
  static const Color primaryColor800 = Color(0xFFE65100);    // Very dark orange
  static const Color primaryColor900 = Color(0xFFBF360C);    // Deepest orange

  /// SECONDARY COLOR VARIATIONS (New Extended Options)
  static const Color secondaryColor50 = Color(0xFFFFF3E0);   // Very light cream
  static const Color secondaryColor100 = Color(0xFFFFE0B2);  // Light cream
  static const Color secondaryColor200 = Color(0xFFFFCC80);  // Soft cream
  static const Color secondaryColor300 = Color(0xFFFFB74D);  // Medium cream
  static const Color secondaryColor400 = Color(0xFFFFA726);  // Medium orange-cream
  static const Color secondaryColor500 = Color.fromARGB(255, 253, 182, 59); // YOUR SECONDARY (default)
  static const Color secondaryColor600 = Color(0xFFFF8A65);  // Darker cream-orange
  static const Color secondaryColor700 = Color(0xFFFF7043);  // Dark cream-orange
  static const Color secondaryColor800 = Color(0xFFFF5722);  // Very dark cream-orange
  static const Color secondaryColor900 = Color(0xFFD84315);  // Deepest cream-orange

  /// TERTIARY COLOR VARIATIONS (New Extended Options)
  static const Color tertiaryColor50 = Color(0xFFE8F5E8);    // Very light green
  static const Color tertiaryColor100 = Color(0xFFC8E6C8);   // Light green
  static const Color tertiaryColor200 = Color(0xFFA5D6A7);   // Soft green
  static const Color tertiaryColor300 = Color(0xFF81C784);   // Medium light green
  static const Color tertiaryColor400 = Color(0xFF66BB6A);   // Medium green
  static const Color tertiaryColor500 = Color(0xFF43A047);   // YOUR TERTIARY (default)
  static const Color tertiaryColor600 = Color(0xFF388E3C);   // Darker green
  static const Color tertiaryColor700 = Color(0xFF2E7D32);   // Dark green
  static const Color tertiaryColor800 = Color(0xFF1B5E20);   // Very dark green
  static const Color tertiaryColor900 = Color(0xFF0D4E14);   // Deepest green

  /// Supporting Colors (Your Original + Extended Options)
  static const Color warmAccent = Color(0xFFF3C623);          // Analogous Yellow - Bright highlights
  static const Color deepAccent = Color(0xFFFF7043);          // Analogous Red-Orange - Energy accents
  static const Color coolBalance = Color(0xFF00ACC1);         // Complementary Teal - Cool balance
  static const Color trustBlue = Color(0xFF2196F3);           // Split-Complementary - Trust elements
  static const Color successGreen = Color(0xFF4CAF50);        // Triadic Green - Success states
  static const Color creativePurple = Color(0xFF9C27B0);      // Triadic Purple - Creative elements

  /// EXTENDED SUPPORTING COLOR VARIATIONS (New Options)
  /// Warm Accent Variations
  static const Color warmAccent50 = Color(0xFFFFFBE6);       // Very light yellow
  static const Color warmAccent100 = Color(0xFFFFF4B3);      // Light yellow
  static const Color warmAccent200 = Color(0xFFFFF082);      // Soft yellow
  static const Color warmAccent300 = Color(0xFFFFF54F);      // Medium yellow
  static const Color warmAccent400 = Color(0xFFFFF828);      // Bright yellow
  static const Color warmAccent500 = Color(0xFFF3C623);      // YOUR WARM ACCENT (default)
  static const Color warmAccent600 = Color(0xFFFFB300);      // Golden yellow
  static const Color warmAccent700 = Color(0xFFFF8F00);      // Deep golden
  static const Color warmAccent800 = Color(0xFFFF6F00);      // Orange-yellow
  static const Color warmAccent900 = Color(0xFFE65100);      // Deep orange-yellow

  /// Cool Balance Variations
  static const Color coolBalance50 = Color(0xFFE0F8FF);      // Very light teal
  static const Color coolBalance100 = Color(0xFFB3E5FC);     // Light teal
  static const Color coolBalance200 = Color(0xFF81D4FA);     // Soft teal
  static const Color coolBalance300 = Color(0xFF4FC3F7);     // Medium teal
  static const Color coolBalance400 = Color(0xFF29B6F6);     // Bright teal
  static const Color coolBalance500 = Color(0xFF00ACC1);     // YOUR COOL BALANCE (default)
  static const Color coolBalance600 = Color(0xFF0097A7);     // Darker teal
  static const Color coolBalance700 = Color(0xFF00838F);     // Dark teal
  static const Color coolBalance800 = Color(0xFF006064);     // Very dark teal
  static const Color coolBalance900 = Color(0xFF004D40);     // Deepest teal

  /// Trust Blue Variations
  static const Color trustBlue50 = Color(0xFFE3F2FD);        // Very light blue
  static const Color trustBlue100 = Color(0xFFBBDEFB);       // Light blue
  static const Color trustBlue200 = Color(0xFF90CAF9);       // Soft blue
  static const Color trustBlue300 = Color(0xFF64B5F6);       // Medium blue
  static const Color trustBlue400 = Color(0xFF42A5F5);       // Bright blue
  static const Color trustBlue500 = Color(0xFF2196F3);       // YOUR TRUST BLUE (default)
  static const Color trustBlue600 = Color(0xFF1E88E5);       // Darker blue
  static const Color trustBlue700 = Color(0xFF1976D2);       // Dark blue
  static const Color trustBlue800 = Color(0xFF1565C0);       // Very dark blue
  static const Color trustBlue900 = Color(0xFF0D47A1);       // Deepest blue

  /// ALTERNATIVE COLOR SCHEMES (New Options)
  /// Monochromatic Orange Scheme
  static const List<Color> monochromaticOrange = [
    Color(0xFFFFF3E0), // Lightest
    Color(0xFFFFE0B2),
    Color(0xFFFFCC80),
    Color(0xFFFFB74D),
    Color(0xFFFFA726), // Your primary
    Color(0xFFFF9800),
    Color(0xFFFF8F00),
    Color(0xFFFF6F00),
    Color(0xFFE65100), // Darkest
  ];

  /// Analogous Warm Scheme
  static const List<Color> analogousWarm = [
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFFC107), // Amber
    Color(0xFFFFA725), // Your orange (primary)
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep orange
    Color(0xFFF44336), // Red
  ];

  /// Complementary Scheme
  static const List<Color> complementaryScheme = [
    Color(0xFFFFA725), // Your warm orange
    Color(0xFF258CFF), // Complementary blue
    Color(0xFFFFD54F), // Light orange
    Color(0xFF64B5F6), // Light blue
    Color(0xFFFF8F00), // Dark orange
    Color(0xFF1976D2), // Dark blue
  ];

  /// Triadic Scheme
  static const List<Color> triadicScheme = [
    Color(0xFFFFA725), // Your orange
    Color(0xFF25FFA7), // Green
    Color(0xFFA725FF), // Purple
    Color(0xFFFFD54F), // Light orange
    Color(0xFF66BB6A), // Light green
    Color(0xFFBA68C8), // Light purple
  ];

  /// Split-Complementary Scheme
  static const List<Color> splitComplementaryScheme = [
    Color(0xFFFFA725), // Your orange
    Color(0xFF25A7FF), // Blue-cyan
    Color(0xFF4725FF), // Blue-violet
    Color(0xFFFFCC80), // Light orange
    Color(0xFF81D4FA), // Light blue-cyan
    Color(0xFF9FA8DA), // Light blue-violet
  ];

  /// SURFACE AND BACKGROUND COLORS (Your Original + Extended)
  static const Color surfaceColor = Color(0xFFFFFFFF);        // Pure White
  static const Color backgroundColorLight = Color(0xFFFAFBFC); // Very Light Blue-Gray
  static const Color backgroundColorDark = Color(0xFF0F172A);  // Dark Blue-Gray
  static const Color cardColor = Color(0xFFFFFFFF);           // Pure White Cards
  static const Color adBackgroundColor = Color(0xFFF1F5F9);   // Light Gray-Blue

  /// EXTENDED SURFACE VARIATIONS (New Options)
  static const Color surfaceVariant1 = Color(0xFFFFFBF5);     // Warm white
  static const Color surfaceVariant2 = Color(0xFFFFF8F0);     // Cream white
  static const Color surfaceVariant3 = Color(0xFFFFFAF0);     // Light cream
  static const Color surfaceVariant4 = Color(0xFFF8F9FA);     // Cool white
  static const Color surfaceVariant5 = Color(0xFFF5F7FA);     // Blue-tinted white

  /// BACKGROUND ALTERNATIVES (New Options)
  static const Color backgroundWarm = Color(0xFFFFF8F0);      // Warm background
  static const Color backgroundCool = Color(0xFFF8FAFC);      // Cool background
  static const Color backgroundNeutral = Color(0xFFFAFBFC);   // Neutral background
  static const Color backgroundSoft = Color(0xFFFDFDFD);      // Soft background
  static const Color backgroundCream = Color(0xFFFFFAF5);     // Cream background

  /// Text Colors (Your Original + Extended Options)
  static const Color textPrimaryLight = Color(0xFF2D1810);    // Warm dark brown
  static const Color textSecondaryLight = Color(0xFF8B5A3C);  // Medium warm brown
  static const Color textPrimaryDark = Color(0xFFFDF6E3);     // Warm light
  static const Color textSecondaryDark = Color(0xFFE8D5C0);   // Warm medium light

  /// EXTENDED TEXT COLOR OPTIONS (New)
  static const Color textLight = Color(0xFF64748B);           // Light gray text
  static const Color textMuted = Color(0xFF94A3B8);           // Muted text
  static const Color textDisabled = Color(0xFFCBD5E1);        // Disabled text
  static const Color textOnPrimary = Color(0xFFFFFFFF);       // White text on primary
  static const Color textOnSecondary = Color(0xFF1F2937);     // Dark text on secondary
  static const Color textAccent = Color(0xFFFFA725);          // Accent text (your primary)
  static const Color textSuccess = Color(0xFF059669);         // Success text
  static const Color textWarning = Color(0xFFD97706);         // Warning text
  static const Color textError = Color(0xFFDC2626);           // Error text
  static const Color textInfo = Color(0xFF2563EB);            // Info text

  /// Status Colors (Your Original + Extended Options)
  static const Color successColor = successGreen;            // Our Triadic Green
  static const Color errorColor = Color(0xFFE53E3E);         // Slightly warm red
  static const Color warningColor = Color(0xFFED8936);       // Warm amber (close to primary)
  static const Color infoColor = trustBlue;                  // Our Complementary Blue

  /// EXTENDED STATUS COLOR VARIATIONS (New)
  /// Success Variations
  static const Color successLight = Color(0xFFDCFCE7);       // Light success background
  static const Color successMedium = Color(0xFF16A34A);      // Medium success
  static const Color successDark = Color(0xFF15803D);        // Dark success
  static const Color successAccent = Color(0xFF22C55E);      // Success accent

  /// Error Variations
  static const Color errorLight = Color(0xFFFEF2F2);         // Light error background
  static const Color errorMedium = Color(0xFFEF4444);        // Medium error
  static const Color errorDark = Color(0xFFDC2626);          // Dark error
  static const Color errorAccent = Color(0xFFF87171);        // Error accent

  /// Warning Variations
  static const Color warningLight = Color(0xFFFEF3C7);       // Light warning background
  static const Color warningMedium = Color(0xFFF59E0B);      // Medium warning
  static const Color warningDark = Color(0xFFD97706);        // Dark warning
  static const Color warningAccent = Color(0xFFFBBF24);      // Warning accent

  /// Info Variations
  static const Color infoLight = Color(0xFFEFF6FF);          // Light info background
  static const Color infoMedium = Color(0xFF3B82F6);         // Medium info
  static const Color infoDark = Color(0xFF1D4ED8);           // Dark info
  static const Color infoAccent = Color(0xFF60A5FA);         // Info accent

  /// Progress Colors (Your Original + Extended)
  static const Color progressExcellent = successGreen;       // Our Triadic Green
  static const Color progressGood = Color(0xFF68D391);       // Light green
  static const Color progressAverage = warmAccent;           // Our Analogous Yellow
  static const Color progressPoor = Color(0xFFFC8181);       // Light warm red

  /// EXTENDED PROGRESS VARIATIONS (New)
  static const Color progressOutstanding = Color(0xFF10B981); // Outstanding (A+)
  static const Color progressVeryGood = Color(0xFF34D399);    // Very Good (A)
  static const Color progressSatisfactory = Color(0xFF84CC16); // Satisfactory (B)
  static const Color progressNeedsWork = Color(0xFFFBAA47);   // Needs Work (C)
  static const Color progressUnsatisfactory = Color(0xFFF87171); // Unsatisfactory (D/F)

  /// Quarter Colors - Your Original + Extended Options
  static const List<Color> quarterColors = [
    primaryColor,      // Q1 - Your Warm Orange (Energy & New Beginnings)
    secondaryColor,    // Q2 - Complementary Blue (Trust & Stability)  
    tertiaryColor,     // Q3 - Triadic Green (Growth & Progress)
    creativePurple,    // Q4 - Triadic Purple (Completion & Achievement)
  ];

  /// EXTENDED QUARTER COLOR SCHEMES (New Options)
  static const List<Color> quarterColorsWarm = [
    Color(0xFFFFA725), // Q1 - Orange
    Color(0xFFFFCA28), // Q2 - Gold
    Color(0xFFFF8F00), // Q3 - Deep Orange
    Color(0xFFFF6F00), // Q4 - Red Orange
  ];

  static const List<Color> quarterColorsCool = [
    Color(0xFF2196F3), // Q1 - Blue
    Color(0xFF00BCD4), // Q2 - Cyan
    Color(0xFF4CAF50), // Q3 - Green
    Color(0xFF9C27B0), // Q4 - Purple
  ];

  static const List<Color> quarterColorsNature = [
    Color(0xFF4CAF50), // Q1 - Green (Spring)
    Color(0xFFFFEB3B), // Q2 - Yellow (Summer)
    Color(0xFFFF9800), // Q3 - Orange (Autumn)
    Color(0xFF2196F3), // Q4 - Blue (Winter)
  ];

  /// Subject Colors - Your Original + Extended Options
  static const List<Color> subjectColors = [
    primaryColor,      // Mathematics - Your Warm Orange (Energy & Focus)
    tertiaryColor,     // Science - Triadic Green (Nature & Discovery)
    creativePurple,    // English - Purple (Creativity & Expression)
    deepAccent,        // History - Red-Orange (Important & Engaging)
    Color(0xFFE91E63), // Arts - Pink (Creativity & Passion)
    coolBalance,       // PE - Teal (Energy & Movement)
    warmAccent,        // Music - Analogous Yellow (Joy & Creativity)
    secondaryColor,    // Others - Complementary Blue (Trust & Knowledge)
  ];

  /// EXTENDED SUBJECT COLOR SCHEMES (New Options)
  static const List<Color> subjectColorsExtended = [
    Color(0xFFFFA725), // Mathematics - Orange (Logic & Energy)
    Color(0xFF4CAF50), // Science - Green (Nature & Growth)
    Color(0xFF9C27B0), // English - Purple (Creativity)
    Color(0xFFFF7043), // History - Red-Orange (Heritage)
    Color(0xFFE91E63), // Arts - Pink (Creativity)
    Color(0xFF00BCD4), // PE - Cyan (Movement)
    Color(0xFFFFC107), // Music - Amber (Joy)
    Color(0xFF2196F3), // Social Studies - Blue (Knowledge)
    Color(0xFF795548), // Geography - Brown (Earth)
    Color(0xFF607D8B), // Technology - Blue Gray (Innovation)
    Color(0xFFFF5722), // Chemistry - Deep Orange (Reaction)
    Color(0xFF8BC34A), // Biology - Light Green (Life)
    Color(0xFF3F51B5), // Physics - Indigo (Universe)
    Color(0xFFFF9800), // Economics - Orange (Growth)
    Color(0xFF9E9E9E), // Philosophy - Gray (Thought)
  ];

  /// Alternative Subject Schemes
  static const List<Color> subjectColorsPastel = [
    Color(0xFFFFD54F), // Mathematics - Soft Yellow
    Color(0xFFA5D6A7), // Science - Soft Green
    Color(0xFFCE93D8), // English - Soft Purple
    Color(0xFFFFAB91), // History - Soft Orange
    Color(0xFFF8BBD9), // Arts - Soft Pink
    Color(0xFF80DEEA), // PE - Soft Cyan
    Color(0xFFFFF59D), // Music - Soft Yellow
    Color(0xFF90CAF9), // Others - Soft Blue
  ];

  static const List<Color> subjectColorsVibrant = [
    Color(0xFFFF6F00), // Mathematics - Vibrant Orange
    Color(0xFF388E3C), // Science - Vibrant Green
    Color(0xFF7B1FA2), // English - Vibrant Purple
    Color(0xFFD84315), // History - Vibrant Red-Orange
    Color(0xFFC2185B), // Arts - Vibrant Pink
    Color(0xFF0097A7), // PE - Vibrant Teal
    Color(0xFFFFA000), // Music - Vibrant Amber
    Color(0xFF1976D2), // Others - Vibrant Blue
  ];

  /// Spotlight Colors (Your Original + Extended)
  static const Color spotlightBackground = Color(0xFFF8F9FA);
  static const Color spotlightBorder = Color(0xFFE5E7EB);
  static const Color spotlightHover = Color(0xFFE2E6EA);
  static const Color spotlightActive = Color(0xFFDDE2E6);

  /// EXTENDED SPOTLIGHT VARIATIONS (New)
  static const Color spotlightWarm = Color(0xFFFFF8F0);      // Warm spotlight
  static const Color spotlightCool = Color(0xFFF0F9FF);      // Cool spotlight
  static const Color spotlightSuccess = Color(0xFFF0FDF4);   // Success spotlight
  static const Color spotlightWarning = Color(0xFFFFFBEB);   // Warning spotlight
  static const Color spotlightError = Color(0xFFFEF2F2);     // Error spotlight
  static const Color spotlightInfo = Color(0xFFEFF6FF);      // Info spotlight

  /// Custom Palette (Your Original + Extended)
  static const Color cream = Color(0xFFFEF3E2);              // Warm cream backgrounds
  static const Color vividYellow = Color(0xFFF3C623);        // Notifications & highlights
  static const Color orangeYellow = Color(0xFFFFB22C);       // Secondary CTAs
  static const Color vividOrange = Color(0xFFFA812F);        // Primary CTAs & energy

  /// EXTENDED CUSTOM PALETTE (New Options)
  static const Color lightCream = Color(0xFFFFFAF5);         // Very light cream
  static const Color mediumCream = Color(0xFFFEF7E8);        // Medium cream
  static const Color darkCream = Color(0xFFFDECD3);          // Dark cream
  static const Color goldYellow = Color(0xFFFFD700);         // Gold yellow
  static const Color sunYellow = Color(0xFFFDD835);          // Sun yellow
  static const Color mellowOrange = Color(0xFFFFB74D);       // Mellow orange
  static const Color brightOrange = Color(0xFFFF9500);       // Bright orange
  static const Color deepOrange = Color(0xFFE65100);         // Deep orange

  /// Gradient Collections (Your Original + Extended)
  static const List<Color> spotlightGradient = [
    cream,
    vividYellow,
    orangeYellow,
    vividOrange,
  ];

  /// NEW GRADIENT COLLECTIONS (Extended Options)
  static const List<Color> sunsetGradient = [
    Color(0xFFFFE082), // Light yellow
    Color(0xFFFFA726), // Your primary orange
    Color(0xFFFF7043), // Red-orange
    Color(0xFFE91E63), // Pink
  ];

  static const List<Color> oceanGradient = [
    Color(0xFF81D4FA), // Light blue
    Color(0xFF29B6F6), // Medium blue
    Color(0xFF2196F3), // Your trust blue
    Color(0xFF1976D2), // Dark blue
  ];

  static const List<Color> forestGradient = [
    Color(0xFFC8E6C8), // Light green
    Color(0xFF81C784), // Medium green
    Color(0xFF4CAF50), // Your success green
    Color(0xFF388E3C), // Dark green
  ];

  static const List<Color> royalGradient = [
    Color(0xFFE1BEE7), // Light purple
    Color(0xFFCE93D8), // Medium purple
    Color(0xFFAB47BC), // Your creative purple
    Color(0xFF8E24AA), // Dark purple
  ];

  static const List<Color> earthGradient = [
    Color(0xFFD7CCC8), // Light brown
    Color(0xFFBCAAA4), // Medium brown
    Color(0xFFA1887F), // Brown
    Color(0xFF8D6E63), // Dark brown
  ];

  /// Professional Neutral Palette (Your Original + Extended)
  static const Color neutralGray50 = Color(0xFFFAFAFA);
  static const Color neutralGray100 = Color(0xFFF5F5F5);
  static const Color neutralGray200 = Color(0xFFEEEEEE);
  static const Color neutralGray300 = Color(0xFFE0E0E0);
  static const Color neutralGray400 = Color(0xFFBDBDBD);
  static const Color neutralGray500 = Color(0xFF9E9E9E);
  static const Color neutralGray600 = Color(0xFF757575);
  static const Color neutralGray700 = Color(0xFF616161);
  static const Color neutralGray800 = Color(0xFF424242);
  static const Color neutralGray900 = Color(0xFF212121);

  /// EXTENDED NEUTRAL VARIATIONS (New Options)
  /// Warm Grays
  static const Color warmGray50 = Color(0xFFFAF9F7);
  static const Color warmGray100 = Color(0xFFF5F5F4);
  static const Color warmGray200 = Color(0xFFE7E5E4);
  static const Color warmGray300 = Color(0xFFD6D3D1);
  static const Color warmGray400 = Color(0xFFA8A29E);
  static const Color warmGray500 = Color(0xFF78716C);
  static const Color warmGray600 = Color(0xFF57534E);
  static const Color warmGray700 = Color(0xFF44403C);
  static const Color warmGray800 = Color(0xFF292524);
  static const Color warmGray900 = Color(0xFF1C1917);

  /// Cool Grays
  static const Color coolGray50 = Color(0xFFF8FAFC);
  static const Color coolGray100 = Color(0xFFF1F5F9);
  static const Color coolGray200 = Color(0xFFE2E8F0);
  static const Color coolGray300 = Color(0xFFCBD5E1);
  static const Color coolGray400 = Color(0xFF94A3B8);
  static const Color coolGray500 = Color(0xFF64748B);
  static const Color coolGray600 = Color(0xFF475569);
  static const Color coolGray700 = Color(0xFF334155);
  static const Color coolGray800 = Color(0xFF1E293B);
  static const Color coolGray900 = Color(0xFF0F172A);

  /// Blue Grays
  static const Color blueGray50 = Color(0xFFF8FAFC);
  static const Color blueGray100 = Color(0xFFF1F5F9);
  static const Color blueGray200 = Color(0xFFE2E8F0);
  static const Color blueGray300 = Color(0xFFCBD5E1);
  static const Color blueGray400 = Color(0xFF94A3B8);
  static const Color blueGray500 = Color(0xFF64748B);
  static const Color blueGray600 = Color(0xFF475569);
  static const Color blueGray700 = Color(0xFF334155);
  static const Color blueGray800 = Color(0xFF1E293B);
  static const Color blueGray900 = Color(0xFF0F172A);

  /// Semantic Color Extensions (Your Original + Extended)
  static const Color successBackground = Color(0xFFF0FFF4);  // Light green background
  static const Color warningBackground = Color(0xFFFFF5E6);  // Warm light background  
  static const Color errorBackground = Color(0xFFFED7D7);    // Light warm red background
  static const Color infoBackground = Color(0xFFEBF8FF);     // Light blue background

  /// EXTENDED SEMANTIC BACKGROUNDS (New Options)
  static const Color successBackgroundLight = Color(0xFFF7FEF7);
  static const Color successBackgroundDark = Color(0xFFDCFCE7);
  static const Color warningBackgroundLight = Color(0xFFFFFDF7);
  static const Color warningBackgroundDark = Color(0xFFFEF3C7);
  static const Color errorBackgroundLight = Color(0xFFFFFAFA);
  static const Color errorBackgroundDark = Color(0xFFFEE2E2);
  static const Color infoBackgroundLight = Color(0xFFFAFBFF);
  static const Color infoBackgroundDark = Color(0xFFDBEAFE);

  /// Elevation Colors (Your Original + Extended)
  static const List<Color> elevationLight = [
    Color(0x0A000000), // Light shadow
    Color(0x14000000), // Medium shadow  
    Color(0x1F000000), // Strong shadow
  ];

  static const List<Color> elevationDark = [
    Color(0x0DFFFFFF), // Light highlight
    Color(0x14FFFFFF), // Medium highlight
    Color(0x1FFFFFFF), // Strong highlight
  ];

  /// EXTENDED ELEVATION OPTIONS (New)
  static const List<Color> elevationWarm = [
    Color(0x0AFFA725), // Light warm shadow
    Color(0x14FFA725), // Medium warm shadow
    Color(0x1FFFA725), // Strong warm shadow
  ];

  static const List<Color> elevationCool = [
    Color(0x0A2196F3), // Light cool shadow
    Color(0x142196F3), // Medium cool shadow
    Color(0x1F2196F3), // Strong cool shadow
  ];

 /// Backward compatibility constants (Fixed for const TextStyle usage)
static const Color textPrimaryColor = textPrimaryLight;
static const Color textSecondaryColor = textSecondaryLight;
static const Color backgroundColor = backgroundColorLight;
static const Color accentColor = secondaryColor;

// Keep this as a getter since ThemeData can't be const
static ThemeData getTheme() => lightTheme;

  /// Constants for gradients and other constant contexts (Your Original)
  static const backgroundColorConst = backgroundColorLight;

  // =============================================================================
  // NEW COLOR SCHEME GETTERS (Extended Functionality)
  // =============================================================================

  /// Get color scheme by type
  static List<Color> getColorScheme(String schemeType) {
    switch (schemeType.toLowerCase()) {
      case 'monochromatic':
        return monochromaticOrange;
      case 'analogous':
        return analogousWarm;
      case 'complementary':
        return complementaryScheme;
      case 'triadic':
        return triadicScheme;
      case 'split_complementary':
        return splitComplementaryScheme;
      default:
        return [primaryColor, secondaryColor, tertiaryColor];
    }
  }

  /// Get quarter colors by theme
  static List<Color> getQuarterScheme(String themeType) {
    switch (themeType.toLowerCase()) {
      case 'warm':
        return quarterColorsWarm;
      case 'cool':
        return quarterColorsCool;
      case 'nature':
        return quarterColorsNature;
      default:
        return quarterColors;
    }
  }

  /// Get subject colors by style
  static List<Color> getSubjectScheme(String style) {
    switch (style.toLowerCase()) {
      case 'extended':
        return subjectColorsExtended;
      case 'pastel':
        return subjectColorsPastel;
      case 'vibrant':
        return subjectColorsVibrant;
      default:
        return subjectColors;
    }
  }

  /// Get gradient by type
  static List<Color> getGradientScheme(String gradientType) {
    switch (gradientType.toLowerCase()) {
      case 'sunset':
        return sunsetGradient;
      case 'ocean':
        return oceanGradient;
      case 'forest':
        return forestGradient;
      case 'royal':
        return royalGradient;
      case 'earth':
        return earthGradient;
      case 'spotlight':
      default:
        return spotlightGradient;
    }
  }

  // =============================================================================
  // Helper method to create safe text styles (NO GOOGLE FONTS)
  // =============================================================================
  
  static TextStyle _poppinsStyle({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Poppins', // Use local Poppins font
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
    );
  }

  // =============================================================================
  // ENHANCED LIGHT THEME (Your Original Structure + LOCAL FONTS)
  // =============================================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      /// ColorScheme enhanced with YOUR WARM COLORS as primary brand
      colorScheme: ColorScheme.light(
        // YOUR WARM BRAND COLORS (Primary Usage - 30%)
        primary: primaryColor,        // YOUR Deep Orange
        onPrimary: Colors.white,
        primaryContainer: cream.withOpacity(0.3),
        onPrimaryContainer: Color(0xFF7C2D12),
        
        // YOUR SECONDARY BRAND COLORS
        secondary: secondaryColor,    // YOUR Medium Orange
        onSecondary: Colors.white,
        secondaryContainer: cream.withOpacity(0.5),
        onSecondaryContainer: Color(0xFF7C2D12),
        
        // YOUR TERTIARY BRAND COLOR
        tertiary: tertiaryColor,      // YOUR Bright Yellow
        onTertiary: Color(0xFF1F2937),
        tertiaryContainer: cream,
        onTertiaryContainer: Color(0xFF7C2D12),
        
        // Neutral Foundation (60% usage)
        surface: surfaceColor,
        onSurface: textPrimaryLight,
        surfaceVariant: backgroundColorLight,
        onSurfaceVariant: textSecondaryLight,
        
        background: backgroundColorLight,
        onBackground: textPrimaryLight,
        
        // Semantic Colors
        error: errorColor,
        onError: Colors.white,
        errorContainer: errorBackground,
        onErrorContainer: Color(0xFF7F1D1D),
        
        // System Colors
        outline: neutralGray300,
        outlineVariant: neutralGray200,
        shadow: Colors.black,
        surfaceTint: primaryColor,
      ),

      /// Typography enhanced for education (LOCAL POPPINS)
      textTheme: TextTheme(
        displayLarge: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w300,
          fontSize: 57,
          height: 1.12,
        ),
        displayMedium: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w400,
          fontSize: 45,
          height: 1.16,
        ),
        displaySmall: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w400,
          fontSize: 36,
          height: 1.22,
        ),
        headlineLarge: _poppinsStyle(
          color: primaryColor,        // YOUR Deep Orange for headlines
          fontWeight: FontWeight.w600,
          fontSize: 32,
          height: 1.25,
        ),
        headlineMedium: _poppinsStyle(
          color: primaryColor,        // YOUR Deep Orange
          fontWeight: FontWeight.w600,
          fontSize: 28,
          height: 1.29,
        ),
        headlineSmall: _poppinsStyle(
          color: primaryColor,        // YOUR Deep Orange
          fontWeight: FontWeight.w600,
          fontSize: 24,
          height: 1.33,
        ),
        titleLarge: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 22,
          height: 1.27,
        ),
        titleMedium: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.5,
        ),
        titleSmall: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.43,
        ),
        bodyLarge: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.43,
        ),
        bodySmall: _poppinsStyle(
          color: textSecondaryLight,
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.33,
        ),
        labelLarge: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.43,
        ),
        labelMedium: _poppinsStyle(
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.33,
        ),
        labelSmall: _poppinsStyle(
          color: neutralGray500,
          fontWeight: FontWeight.w500,
          fontSize: 11,
          height: 1.45,
        ),
      ),

      /// AppBar Theme (YOUR WARM ORANGE as primary)
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,  // YOUR Deep Orange
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: elevationLight[1],
        surfaceTintColor: primaryColor.withOpacity(0.05),
        titleTextStyle: _poppinsStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        toolbarTextStyle: _poppinsStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      /// Card Theme (Enhanced from your original)
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: elevationLight[0],
        surfaceTintColor: primaryColor.withOpacity(0.02),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: surfaceColor,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      /// Button Themes (YOUR ORANGE COLORS as primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,  // YOUR Deep Orange
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: elevationLight[1],
          surfaceTintColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _poppinsStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),

      /// Text Button Theme (Enhanced from your original)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _poppinsStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// Outlined Button Theme (Enhanced from your original)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _poppinsStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// Input Decoration Theme (Enhanced from your original)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutralGray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: _poppinsStyle(
          color: textSecondaryLight,
        ),
        labelStyle: _poppinsStyle(
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: _poppinsStyle(
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: _poppinsStyle(
          color: errorColor,
        ),
      ),

      /// FAB Theme (Complementary color for visual hierarchy)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor, // Complementary Blue for contrast
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 10,
        hoverElevation: 10,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      /// Snackbar Theme (Harmonious accent color for actions)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: neutralGray800,
        contentTextStyle: _poppinsStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        actionTextColor: warmAccent, // Analogous Yellow for actions
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),

      /// Divider Theme (Enhanced from your original)
      dividerTheme: DividerThemeData(
        color: neutralGray200,
        thickness: 1,
        space: 16,
      ),

      /// Chip Theme (Enhanced from your original)
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColorLight,
        selectedColor: primaryColor.withOpacity(0.12),
        disabledColor: neutralGray200,
        labelStyle: _poppinsStyle(
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: _poppinsStyle(
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        pressElevation: 4,
      ),

      /// Tooltip Theme (Enhanced from your original)
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: neutralGray800.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: elevationLight[1],
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: _poppinsStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      /// Switch Theme (Enhanced)
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return neutralGray400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return neutralGray300;
        }),
      ),

      /// Radio Theme (Enhanced)
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return neutralGray400;
        }),
        overlayColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
      ),

      /// Checkbox Theme (Enhanced)
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        overlayColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
      ),
    );
  }

  // =============================================================================
  // ENHANCED DARK THEME (Your Original Structure + LOCAL FONTS)
  // =============================================================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.dark(
        primary: primaryColor,        // Your Warm Orange (works in dark too)
        onPrimary: Color(0xFF1F2937),
        primaryContainer: Color(0xFF7C2D12),
        onPrimaryContainer: Color(0xFFFFF5E6),
        
        secondary: secondaryColor,    // Complementary Blue  
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF0D47A1),
        onSecondaryContainer: Color(0xFFE3F2FD),
        
        tertiary: tertiaryColor,      // Triadic Green
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF1B5E20),
        onTertiaryContainer: Color(0xFFE8F5E8),
        
        surface: Color(0xFF1F2937),
        onSurface: textPrimaryDark,
        surfaceVariant: Color(0xFF374151),
        onSurfaceVariant: textSecondaryDark,
        
        background: backgroundColorDark,
        onBackground: textPrimaryDark,
        
        error: Color(0xFFF87171),
        onError: Color(0xFF7F1D1D),
        errorContainer: errorColor,
        onErrorContainer: errorBackground,
        
        outline: Color(0xFF4B5563),
        outlineVariant: Color(0xFF374151),
        shadow: Colors.black,
        surfaceTint: Color(0xFF60A5FA),
      ),

      textTheme: TextTheme(
        displayLarge: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w300, fontSize: 57),
        displayMedium: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w400, fontSize: 45),
        displaySmall: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w400, fontSize: 36),
        headlineLarge: _poppinsStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 32),
        headlineMedium: _poppinsStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 28),
        headlineSmall: _poppinsStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 24),
        titleLarge: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 22),
        titleMedium: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w400, fontSize: 16),
        bodyMedium: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: _poppinsStyle(color: textSecondaryDark, fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: _poppinsStyle(color: textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 14),
        labelMedium: _poppinsStyle(color: textSecondaryDark, fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: _poppinsStyle(color: textSecondaryDark, fontWeight: FontWeight.w500, fontSize: 11),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: textPrimaryDark,
        elevation: 0,
        titleTextStyle: _poppinsStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        iconTheme: IconThemeData(color: textSecondaryDark, size: 24),
      ),

      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Color(0xFF1F2937),
        shadowColor: Colors.black.withOpacity(0.5),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,    // Your Warm Orange  
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _poppinsStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4B5563)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4B5563)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2), // YOUR Deep Orange
        ),
        hintStyle: _poppinsStyle(color: textSecondaryDark),
        labelStyle: _poppinsStyle(color: textSecondaryDark),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tertiaryColor,  // Triadic Green for variety in dark mode
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // =============================================================================
  // YOUR ORIGINAL UTILITY METHODS (PRESERVED + ENHANCED)
  // =============================================================================
  
  /// Get subject color based on index (Your original method)
  static Color getSubjectColor(int index) {
    return subjectColors[index % subjectColors.length];
  }

  /// Get quarter color based on quarter (Your original method)
  static Color getQuarterColor(int quarter) {
    return quarterColors[(quarter - 1) % quarterColors.length];
  }

  /// Get progress color based on percentage (Your original method)
  static Color getProgressColor(double percentage) {
    if (percentage >= 90) return progressExcellent;
    if (percentage >= 80) return progressGood;
    if (percentage >= 70) return progressAverage;
    return progressPoor;
  }

  // =============================================================================
  // NEW EXTENDED UTILITY METHODS (Enhanced Functionality)
  // =============================================================================
  
  /// Get primary color variation by shade (50-900)
  static Color getPrimaryShade(int shade) {
    switch (shade) {
      case 50: return primaryColor50;
      case 100: return primaryColor100;
      case 200: return primaryColor200;
      case 300: return primaryColor300;
      case 400: return primaryColor400;
      case 500: return primaryColor500; // Default primary
      case 600: return primaryColor600;
      case 700: return primaryColor700;
      case 800: return primaryColor800;
      case 900: return primaryColor900;
      default: return primaryColor;
    }
  }

  /// Get secondary color variation by shade (50-900)
  static Color getSecondaryShade(int shade) {
    switch (shade) {
      case 50: return secondaryColor50;
      case 100: return secondaryColor100;
      case 200: return secondaryColor200;
      case 300: return secondaryColor300;
      case 400: return secondaryColor400;
      case 500: return secondaryColor500; // Default secondary
      case 600: return secondaryColor600;
      case 700: return secondaryColor700;
      case 800: return secondaryColor800;
      case 900: return secondaryColor900;
      default: return secondaryColor;
    }
  }

  /// Get tertiary color variation by shade (50-900)
  static Color getTertiaryShade(int shade) {
    switch (shade) {
      case 50: return tertiaryColor50;
      case 100: return tertiaryColor100;
      case 200: return tertiaryColor200;
      case 300: return tertiaryColor300;
      case 400: return tertiaryColor400;
      case 500: return tertiaryColor500; // Default tertiary
      case 600: return tertiaryColor600;
      case 700: return tertiaryColor700;
      case 800: return tertiaryColor800;
      case 900: return tertiaryColor900;
      default: return tertiaryColor;
    }
  }

  /// Get neutral color by type and shade
  static Color getNeutralColor(String type, int shade) {
    switch (type.toLowerCase()) {
      case 'warm':
        switch (shade) {
          case 50: return warmGray50;
          case 100: return warmGray100;
          case 200: return warmGray200;
          case 300: return warmGray300;
          case 400: return warmGray400;
          case 500: return warmGray500;
          case 600: return warmGray600;
          case 700: return warmGray700;
          case 800: return warmGray800;
          case 900: return warmGray900;
          default: return warmGray500;
        }
      case 'cool':
        switch (shade) {
          case 50: return coolGray50;
          case 100: return coolGray100;
          case 200: return coolGray200;
          case 300: return coolGray300;
          case 400: return coolGray400;
          case 500: return coolGray500;
          case 600: return coolGray600;
          case 700: return coolGray700;
          case 800: return coolGray800;
          case 900: return coolGray900;
          default: return coolGray500;
        }
      case 'blue':
        switch (shade) {
          case 50: return blueGray50;
          case 100: return blueGray100;
          case 200: return blueGray200;
          case 300: return blueGray300;
          case 400: return blueGray400;
          case 500: return blueGray500;
          case 600: return blueGray600;
          case 700: return blueGray700;
          case 800: return blueGray800;
          case 900: return blueGray900;
          default: return blueGray500;
        }
      default: // neutral
        switch (shade) {
          case 50: return neutralGray50;
          case 100: return neutralGray100;
          case 200: return neutralGray200;
          case 300: return neutralGray300;
          case 400: return neutralGray400;
          case 500: return neutralGray500;
          case 600: return neutralGray600;
          case 700: return neutralGray700;
          case 800: return neutralGray800;
          case 900: return neutralGray900;
          default: return neutralGray500;
        }
    }
  }

  /// Get progress color with extended scale
  static Color getProgressColorExtended(double percentage) {
    if (percentage >= 95) return progressOutstanding;     // A+ (95-100%)
    if (percentage >= 90) return progressExcellent;       // A (90-94%)
    if (percentage >= 85) return progressVeryGood;        // A- (85-89%)
    if (percentage >= 80) return progressGood;            // B+ (80-84%)
    if (percentage >= 75) return progressSatisfactory;    // B (75-79%)
    if (percentage >= 70) return progressAverage;         // B- (70-74%)
    if (percentage >= 65) return progressNeedsWork;       // C (65-69%)
    return progressUnsatisfactory;                        // D/F (<65%)
  }

  // =============================================================================
  // YOUR ORIGINAL GRADIENT UTILITIES (PRESERVED + ENHANCED)
  // =============================================================================
  
  /// Primary gradient (YOUR WARM ORANGE COLORS)
  static LinearGradient get primaryLinearGradient {
    return LinearGradient(
      colors: [primaryColor, secondaryColor], // YOUR Deep Orange → Medium Orange
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Background gradient (Enhanced from your original) 
  static LinearGradient get backgroundLinearGradient {
    return LinearGradient(
      colors: [backgroundColorLight, surfaceColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Card gradient (Enhanced from your original)
  static LinearGradient get cardLinearGradient {
    return LinearGradient(
      colors: [surfaceColor, backgroundColorLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Your original spotlight gradient (Preserved)
  static LinearGradient get spotlightLinearGradient {
    return const LinearGradient(
      colors: spotlightGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // =============================================================================
  // NEW ENHANCED GRADIENT UTILITIES
  // =============================================================================
  
  /// Warm accent gradient using harmonious colors
  static LinearGradient get warmAccentGradient {
    return LinearGradient(
      colors: [warmAccent, primaryColor, deepAccent], // Yellow → Orange → Red-Orange
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Cool balance gradient 
  static LinearGradient get coolBalanceGradient {
    return LinearGradient(
      colors: [trustBlue, secondaryColor, coolBalance], // Blue → Deep Blue → Teal
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Success gradient using triadic harmony
  static LinearGradient get successGradient {
    return LinearGradient(
      colors: [successColor, tertiaryColor], // Green harmony
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Subtle warm background gradient for cards
  static LinearGradient get subtleBackgroundGradient {
    return LinearGradient(
      colors: [
        surfaceColor,
        backgroundColorLight.withOpacity(0.3),
        surfaceColor,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Get gradient by name
  static LinearGradient getNamedGradient(String gradientName) {
    switch (gradientName.toLowerCase()) {
      case 'primary':
        return primaryLinearGradient;
      case 'background':
        return backgroundLinearGradient;
      case 'card':
        return cardLinearGradient;
      case 'spotlight':
        return spotlightLinearGradient;
      case 'warm_accent':
        return warmAccentGradient;
      case 'cool_balance':
        return coolBalanceGradient;
      case 'success':
        return successGradient;
      case 'subtle_background':
        return subtleBackgroundGradient;
      case 'sunset':
        return LinearGradient(colors: sunsetGradient);
      case 'ocean':
        return LinearGradient(colors: oceanGradient);
      case 'forest':
        return LinearGradient(colors: forestGradient);
      case 'royal':
        return LinearGradient(colors: royalGradient);
      case 'earth':
        return LinearGradient(colors: earthGradient);
      default:
        return primaryLinearGradient;
    }
  }

  // =============================================================================
  // NEW UTILITY METHODS (ENHANCED FUNCTIONALITY)
  // =============================================================================
  
  /// Get semantic color with background option (Enhanced from your original)
  static Color getSemanticColor(String type, {bool isBackground = false, String intensity = 'medium'}) {
    switch (type.toLowerCase()) {
      case 'success':
        if (isBackground) {
          switch (intensity) {
            case 'light': return successBackgroundLight;
            case 'dark': return successBackgroundDark;
            default: return successBackground;
          }
        } else {
          switch (intensity) {
            case 'light': return successLight;
            case 'dark': return successDark;
            case 'accent': return successAccent;
            default: return successColor;
          }
        }
      case 'warning': 
        if (isBackground) {
          switch (intensity) {
            case 'light': return warningBackgroundLight;
            case 'dark': return warningBackgroundDark;
            default: return warningBackground;
          }
        } else {
          switch (intensity) {
            case 'light': return warningLight;
            case 'dark': return warningDark;
            case 'accent': return warningAccent;
            default: return warningColor;
          }
        }
      case 'error':
        if (isBackground) {
          switch (intensity) {
            case 'light': return errorBackgroundLight;
            case 'dark': return errorBackgroundDark;
            default: return errorBackground;
          }
        } else {
          switch (intensity) {
            case 'light': return errorLight;
            case 'dark': return errorDark;
            case 'accent': return errorAccent;
            default: return errorColor;
          }
        }
      case 'info':
        if (isBackground) {
          switch (intensity) {
            case 'light': return infoBackgroundLight;
            case 'dark': return infoBackgroundDark;
            default: return infoBackground;
          }
        } else {
          switch (intensity) {
            case 'light': return infoLight;
            case 'dark': return infoDark;
            case 'accent': return infoAccent;
            default: return infoColor;
          }
        }
      default:
        return neutralGray500;
    }
  }

  /// Get elevation shadow (Enhanced from your original)
  static List<BoxShadow> getElevationShadow(int level, {String shadowType = 'neutral'}) {
    List<Color> shadows;
    switch (shadowType.toLowerCase()) {
      case 'warm':
        shadows = elevationWarm;
        break;
      case 'cool':
        shadows = elevationCool;
        break;
      case 'dark':
        shadows = elevationDark;
        break;
      default:
        shadows = elevationLight;
    }

    switch (level) {
      case 1:
        return [
          BoxShadow(
            color: shadows[0],
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: shadows[1],
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: shadows[2],
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: shadows[2],
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      case 5:
        return [
          BoxShadow(
            color: shadows[2],
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ];
      default:
        return [];
    }
  }

  /// Get text color with contrast (Enhanced from your original)
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate luminance to determine if text should be dark or light
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimaryLight : Colors.white;
  }

  /// Color blend utility (Your original - preserved)
  static Color blendColors(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
  }

  /// Get surface color by type
  static Color getSurfaceColor(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'warm': return surfaceVariant1;
      case 'cream': return surfaceVariant2;
      case 'light_cream': return surfaceVariant3;
      case 'cool': return surfaceVariant4;
      case 'blue_tint': return surfaceVariant5;
      default: return surfaceColor;
    }
  }

  /// Get background color by type
  static Color getBackgroundColor(String backgroundType) {
    switch (backgroundType.toLowerCase()) {
      case 'warm': return backgroundWarm;
      case 'cool': return backgroundCool;
      case 'neutral': return backgroundNeutral;
      case 'soft': return backgroundSoft;
      case 'cream': return backgroundCream;
      case 'dark': return backgroundColorDark;
      default: return backgroundColorLight;
    }
  }

  /// Get spotlight color by type
  static Color getSpotlightColor(String spotlightType) {
    switch (spotlightType.toLowerCase()) {
      case 'warm': return spotlightWarm;
      case 'cool': return spotlightCool;
      case 'success': return spotlightSuccess;
      case 'warning': return spotlightWarning;
      case 'error': return spotlightError;
      case 'info': return spotlightInfo;
      default: return spotlightBackground;
    }
  }
}