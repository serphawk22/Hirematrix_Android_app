import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class BlogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const BlogDetailScreen({super.key, required this.post});

  String _stripHtml(String html) {
    if (html.isEmpty) return '';
    // Normalize newlines and carriage returns
    String result = html.replaceAll('\r', '');

    // Insert newlines for paragraph, list item and line break tags
    result = result
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');

    // Strip all remaining HTML tags
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode common HTML entities
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"');

    // Collapse consecutive newlines down to at most 2 newlines to prevent unwanted whitespace blocks
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode;

    final title = post['title'] ?? 'Career Insight';
    final coverImage = post['cover_image'] ?? '';
    final isFeatured =
        post['featured'] == 1 ||
        post['featured'] == true ||
        post['featured'] == '1';
    final author = post['author_name'] ?? 'HireMatrix Team';
    final contentHtml = post['content'] ?? post['excerpt'] ?? '';
    final cleanedContent = _stripHtml(contentHtml);
    final publishedAt = post['published_at'] ?? post['created_at'] ?? '';

    String formattedDate = '';
    try {
      if (publishedAt.isNotEmpty) {
        final dt = DateTime.parse(publishedAt.toString());
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        formattedDate =
            '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
      }
    } catch (_) {
      formattedDate = 'Recently';
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        title: Text(
          'Article Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge & Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isFeatured
                            ? AppColors.getSecondary(isDark).withOpacity(0.15)
                            : AppColors.getPrimary(isDark).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFeatured ? 'Featured' : 'Blog',
                        style: TextStyle(
                          color: isFeatured
                              ? AppColors.getSecondary(isDark)
                              : AppColors.getPrimary(isDark),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: AppColors.getTextMuted(isDark),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Article Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Author note
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 16,
                      color: AppColors.getTextMuted(isDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'By $author',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextMuted(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cover Image
                if (coverImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coverImage,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        width: double.infinity,
                        color: AppColors.getPrimary(isDark).withOpacity(0.1),
                        child: Icon(
                          Icons.newspaper,
                          color: AppColors.getPrimary(isDark),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                if (coverImage.isNotEmpty) const SizedBox(height: 24),

                // Article text content (Justified alignment)
                Text(
                  cleanedContent,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
