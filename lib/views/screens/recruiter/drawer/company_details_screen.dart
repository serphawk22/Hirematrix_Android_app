import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';

class CompanyDetailsScreen extends StatefulWidget {
  final bool isStandalone;
  const CompanyDetailsScreen({super.key, this.isStandalone = false});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _companyData = {};
  String? _logoUrl;
  List<String> _workplacePhotos = [];

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _careersController = TextEditingController();
  final _industryController = TextEditingController();
  final _sizeController = TextEditingController();
  final _hqController = TextEditingController();
  final _branchesController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _aboutController = TextEditingController();

  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();

  final _missionController = TextEditingController();
  final _cultureController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _tourTitleController = TextEditingController();
  final _tourUrlController = TextEditingController();
  final _tourSummaryController = TextEditingController();

  final _hrEmailController = TextEditingController();
  final _recruiterPhoneController = TextEditingController();
  bool _isContactPublic = true;

  String? _lastFetchedRecruiterId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthController>(context);
    if (auth.currentRecruiter != null &&
        auth.currentRecruiter!.id != _lastFetchedRecruiterId) {
      _lastFetchedRecruiterId = auth.currentRecruiter!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchData();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _careersController.dispose();
    _industryController.dispose();
    _sizeController.dispose();
    _hqController.dispose();
    _branchesController.dispose();
    _shortDescController.dispose();
    _aboutController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _missionController.dispose();
    _cultureController.dispose();
    _benefitsController.dispose();
    _tourTitleController.dispose();
    _tourUrlController.dispose();
    _tourSummaryController.dispose();
    _hrEmailController.dispose();
    _recruiterPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final recruiter = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter;
    if (recruiter != null) {
      try {
        final response = await _apiService.fetchCompanyProfile(recruiter.id);
        if (response['success'] == true) {
          _companyData = response['company'] ?? {};
          final logoPath = _companyData['company_logo'] ?? _companyData['logo'];
          if (logoPath != null && logoPath.toString().isNotEmpty) {
            _logoUrl = await _apiService.getImageUrl(logoPath.toString());
          }

          _workplacePhotos = [];
          final rawPhotos =
              _companyData['workplace_photos_urls'] ??
              _companyData['workplace_photos'];
          for (var photo in _extractWorkplacePhotos(rawPhotos)) {
            _workplacePhotos.add(await _apiService.getImageUrl(photo));
          }

          _populateFields();
        }
      } catch (e) {
        debugPrint("Error fetching company profile: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load company details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<String> _extractWorkplacePhotos(dynamic rawPhotos) {
    if (rawPhotos == null) return [];
    if (rawPhotos is List) {
      return rawPhotos
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final rawString = rawPhotos.toString().trim();
    if (rawString.isEmpty) return [];

    try {
      final decoded = json.decode(rawString);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // fallback to comma separated values
    }

    return rawString
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _populateFields() {
    _nameController.text =
        _companyData['name'] ?? _companyData['company_name'] ?? '';
    _websiteController.text = _companyData['website'] ?? '';
    _careersController.text =
        _companyData['career_page'] ?? _companyData['careers_page_url'] ?? '';
    _industryController.text = _companyData['industry'] ?? '';
    _sizeController.text =
        _companyData['size'] ?? _companyData['company_size'] ?? '';
    _hqController.text =
        _companyData['hq'] ?? _companyData['hq_location'] ?? '';
    _branchesController.text =
        _companyData['branches'] ?? _companyData['branch_locations'] ?? '';
    _shortDescController.text = _companyData['short_description'] ?? '';
    _aboutController.text =
        _companyData['what_we_do'] ?? _companyData['about_company'] ?? '';

    _linkedinController.text =
        _companyData['linkedin'] ?? _companyData['linkedin_url'] ?? '';
    _twitterController.text =
        _companyData['twitter'] ?? _companyData['twitter_url'] ?? '';
    _facebookController.text =
        _companyData['facebook'] ?? _companyData['facebook_url'] ?? '';
    _instagramController.text =
        _companyData['instagram'] ?? _companyData['instagram_url'] ?? '';
    _youtubeController.text =
        _companyData['youtube'] ?? _companyData['youtube_url'] ?? '';

    _missionController.text = _companyData['mission_values'] ?? '';
    _cultureController.text =
        _companyData['culture_summary'] ??
        _companyData['culture_environment'] ??
        '';
    _benefitsController.text = _companyData['employee_benefits'] ?? '';
    _tourTitleController.text = _companyData['office_tour_title'] ?? '';
    _tourUrlController.text = _companyData['office_tour_url'] ?? '';
    _tourSummaryController.text = _companyData['office_tour_summary'] ?? '';

    _hrEmailController.text =
        _companyData['contact_email'] ?? _companyData['hr_support_email'] ?? '';
    _recruiterPhoneController.text =
        _companyData['contact_phone'] ?? _companyData['recruiter_phone'] ?? '';
    _isContactPublic =
        _companyData['contact_public'] == 1 ||
        _companyData['contact_public'] == true ||
        _companyData['public_contact_visibility'] == 1 ||
        _companyData['public_contact_visibility'] == true;
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      setState(() => _isSaving = true);
      final recruiter = Provider.of<AuthController>(
        context,
        listen: false,
      ).currentRecruiter;
      final response = await _apiService.uploadCompanyImage(
        image.path,
        recruiter!.id,
        type: 'logo',
      );

      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchData();
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Upload failed')),
        );
      }
    }
  }

  Future<void> _addWorkplacePhoto() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty && mounted) {
      final recruiter = Provider.of<AuthController>(
        context,
        listen: false,
      ).currentRecruiter;
      if (recruiter == null) return;

      setState(() => _isSaving = true);

      int successCount = 0;
      for (var img in images) {
        final response = await _apiService.uploadCompanyImage(
          img.path,
          recruiter.id,
          type: 'workplace',
        );
        if (response['success'] == true) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount photos uploaded'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchData();
      }
    }
  }

  Future<void> _deletePhoto(String url) async {
    final recruiter = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter;
    String relativePath = url;
    final uploadsIndex = relativePath.indexOf('uploads/');
    if (uploadsIndex != -1) {
      relativePath = relativePath.substring(uploadsIndex);
    }

    setState(() => _isSaving = true);
    final response = await _apiService.deleteCompanyImage(
      recruiter!.id,
      relativePath,
    );

    if (mounted) {
      if (response['success'] == true) {
        _fetchData();
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove photo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final recruiter = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter;

    final data = {
      'recruiter_id': recruiter!.id,
      'company_id': _companyData['id'] ?? _companyData['company_id'],
      'name': _nameController.text,
      'website': _websiteController.text,
      'career_page': _careersController.text,
      'industry': _industryController.text,
      'size': _sizeController.text,
      'hq': _hqController.text,
      'branches': _branchesController.text,
      'short_description': _shortDescController.text,
      'what_we_do': _aboutController.text,
      'linkedin': _linkedinController.text,
      'twitter': _twitterController.text,
      'facebook': _facebookController.text,
      'instagram': _instagramController.text,
      'youtube': _youtubeController.text,
      'mission_values': _missionController.text,
      'culture_summary': _cultureController.text,
      'employee_benefits': _benefitsController.text,
      'office_tour_title': _tourTitleController.text,
      'office_tour_url': _tourUrlController.text,
      'office_tour_summary': _tourSummaryController.text,
      'contact_email': _hrEmailController.text,
      'contact_phone': _recruiterPhoneController.text,
      'contact_public': _isContactPublic ? 1 : 0,
    };

    try {
      final response = await _apiService.updateCompanyProfile(data);

      if (mounted) {
        setState(() => _isSaving = false);
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Update failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentScaffold = Scaffold.maybeOf(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: (parentScaffold != null && parentScaffold.hasDrawer)
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => parentScaffold.openDrawer(),
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
        title: Text(
          'Company Profile',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, color: Colors.green),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Company Information', isDark),
                    const SizedBox(height: 12),
                    _buildInfoForm(isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Social Profiles', isDark),
                    const SizedBox(height: 12),
                    _buildSocialForm(isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Employer Branding', isDark),
                    const SizedBox(height: 12),
                    _buildBrandingForm(isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Contact Visibility', isDark),
                    const SizedBox(height: 12),
                    _buildContactForm(isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.getText(isDark).withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                  ),
                ),
                child: _logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: _logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.business_rounded,
                            size: 40,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business_rounded,
                        size: 40,
                        color: AppColors.getPrimary(isDark),
                      ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: InkWell(
                  onTap: _pickLogo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? 'Company Name'
                      : _nameController.text,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _industryController.text.isEmpty
                      ? 'Industry'
                      : _industryController.text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _sizeController.text.isEmpty
                        ? 'Size Not Set'
                        : _sizeController.text,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoForm(bool isDark) {
    return _buildFormContainer(isDark, [
      _buildTextField(
        _nameController,
        'Company Name',
        'Organization Name',
        Icons.business_rounded,
        isDark,
      ),
      _buildTextField(
        _websiteController,
        'Main Website',
        'https://...',
        Icons.language_rounded,
        isDark,
      ),
      _buildTextField(
        _careersController,
        'Careers Page URL',
        'https://...',
        Icons.link_rounded,
        isDark,
      ),
      _buildTextField(
        _industryController,
        'Industry',
        'e.g. Technology',
        Icons.category_rounded,
        isDark,
      ),
      _buildCompanySizeDropdown(isDark),
      _buildTextField(
        _hqController,
        'HQ Location',
        'City, Country',
        Icons.location_on_rounded,
        isDark,
      ),
      _buildTextField(
        _branchesController,
        'Branch Locations',
        'Other offices',
        Icons.map_rounded,
        isDark,
      ),
      _buildTextField(
        _shortDescController,
        'Short Description',
        'Brief tagline',
        Icons.description_rounded,
        isDark,
        maxLines: 2,
      ),
      _buildTextField(
        _aboutController,
        'About Company',
        'Full description',
        Icons.info_rounded,
        isDark,
        maxLines: 4,
      ),
    ]);
  }

  Widget _buildSocialForm(bool isDark) {
    return _buildFormContainer(isDark, [
      _buildTextField(
        _linkedinController,
        'LinkedIn URL',
        'Profile link',
        Icons.link,
        isDark,
      ),
      _buildTextField(
        _twitterController,
        'Twitter/X URL',
        'Profile link',
        Icons.link,
        isDark,
      ),
      _buildTextField(
        _facebookController,
        'Facebook URL',
        'Profile link',
        Icons.link,
        isDark,
      ),
      _buildTextField(
        _instagramController,
        'Instagram URL',
        'Profile link',
        Icons.link,
        isDark,
      ),
      _buildTextField(
        _youtubeController,
        'YouTube URL',
        'Channel link',
        Icons.link,
        isDark,
      ),
    ]);
  }

  Widget _buildBrandingForm(bool isDark) {
    return _buildFormContainer(isDark, [
      _buildTextField(
        _missionController,
        'Mission & Values',
        'What you stand for',
        Icons.auto_awesome_rounded,
        isDark,
        maxLines: 3,
      ),
      _buildTextField(
        _cultureController,
        'Culture & Environment',
        'Work atmosphere',
        Icons.favorite_rounded,
        isDark,
        maxLines: 3,
      ),
      _buildTextField(
        _benefitsController,
        'Employee Benefits',
        'Perks and advantages',
        Icons.card_giftcard_rounded,
        isDark,
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      _buildSectionHeader('Workplace Photos', isDark),
      const SizedBox(height: 12),
      _buildPhotosGrid(isDark),
      const SizedBox(height: 12),
      _buildTextField(
        _tourTitleController,
        'Office Tour Title',
        'e.g. Welcome to our HQ',
        Icons.movie_rounded,
        isDark,
      ),
      _buildTextField(
        _tourUrlController,
        'Office Tour Video URL',
        'Video link',
        Icons.videocam_rounded,
        isDark,
      ),
      _buildTextField(
        _tourSummaryController,
        'Office Tour Summary',
        'Video description',
        Icons.notes_rounded,
        isDark,
        maxLines: 2,
      ),
    ]);
  }

  Widget _buildContactForm(bool isDark) {
    return _buildFormContainer(isDark, [
      _buildTextField(
        _hrEmailController,
        'HR / Support Email',
        'contact@company.com',
        Icons.email_rounded,
        isDark,
      ),
      _buildTextField(
        _recruiterPhoneController,
        'Recruiter Phone Number',
        '+1...',
        Icons.phone_rounded,
        isDark,
      ),
      SwitchListTile(
        title: Text(
          'Public Contact Visibility',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Show contact info on public company profile',
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
        ),
        value: _isContactPublic,
        onChanged: (val) => setState(() => _isContactPublic = val),
        activeThumbColor: AppColors.getPrimary(isDark),
        contentPadding: EdgeInsets.zero,
      ),
    ]);
  }

  Widget _buildFormContainer(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool isDark, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[100]!,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[100]!,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.getPrimary(isDark)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCompanySizeDropdown(bool isDark) {
    final sizes = ['1-10', '10-50', '50-200', '200-500', '500-1000', '1000+'];
    final currentVal = sizes.contains(_sizeController.text)
        ? _sizeController.text
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentVal,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: 'Company Size',
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.people_rounded,
            size: 18,
            color: AppColors.getPrimary(isDark),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[100]!,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[100]!,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.getPrimary(isDark)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        dropdownColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        items: sizes
            .map(
              (size) => DropdownMenuItem<String>(
                value: size,
                child: Text(
                  size,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ),
            )
            .toList(),
        onChanged: (val) {
          setState(() {
            _sizeController.text = val ?? '';
          });
        },
      ),
    );
  }

  Widget _buildPhotosGrid(bool isDark) {
    return Column(
      children: [
        if (_workplacePhotos.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _workplacePhotos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = _workplacePhotos[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _deletePhoto(url),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_workplacePhotos.isNotEmpty) const SizedBox(height: 12),
        InkWell(
          onTap: _addWorkplacePhoto,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.getPrimary(isDark),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Photos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
