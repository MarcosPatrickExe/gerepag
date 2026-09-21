import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';
import '../services/ai_chat_service.dart';

class ProposalGeneratorScreen extends StatefulWidget {
  const ProposalGeneratorScreen({super.key});

  @override
  State<ProposalGeneratorScreen> createState() => _ProposalGeneratorScreenState();
}

class _ProposalGeneratorScreenState extends State<ProposalGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _realtimeService = RealtimeDbService();

  // Inputs
  final _clientController = TextEditingController(text: 'Tech Startup XYZ');
  final _descriptionController = TextEditingController(
    text: 'Site institucional moderno com painel administrativo simples e formulário de contato.',
  );
  final _scopeItemController = TextEditingController();
  final _projectNameController = TextEditingController(text: 'Projeto Website Completo');
  final _customPresetNameController = TextEditingController(text: 'Serviço Personalizado');
  final _newScopeItemController = TextEditingController();
  final _freelancerNameController = TextEditingController(text: 'Freelancer Autônomo');
  final _freelancerContactController = TextEditingController(text: 'contato@empresa.com.br');

  @override
  void dispose() {
    _clientController?.dispose();
    _descriptionController?.dispose();
    _scopeItemController?.dispose();
    _projectNameController?.dispose();
    _customPresetNameController?.dispose();
    _newScopeItemController?.dispose();
    _freelancerNameController?.dispose();
    _freelancerContactController?.dispose();
    super.dispose();
  }
  double _designRate = 100.0;
  double _devRate = 120.0;
  bool _isFixedPrice = false;
  double _fixedPriceAmount = 15000.0;
  bool _isGeneratingScope = false;
  int _installments = 3;
  double _interestRate = 0.0;

  // Selected Preset
  String _selectedPreset = 'website';
  final List<Map<String, dynamic>> _presets = [
    {
      'id': 'website',
      'name': 'Website Completo 🌐',
      'designHours': 40,
      'devHours': 80,
      'seoCost': 1500.0,
      'hostingCost': 300.0,
      'maintenanceCost': 2100.0,
      'designDays': 7,
      'devDays': 21,
      'deployDays': 28,
      'scope': [
        'Homepage responsiva premium',
        '5 páginas internas institucionais',
        'Formulário de contato integrado',
        'SEO básico on-page configurado',
        'Hospedagem inclusa por 1 ano',
        'Certificado de Segurança SSL ativo',
        'Suporte & Manutenção por 3 meses',
      ],
    },
    {
      'id': 'landing_page',
      'name': 'Landing Page de Vendas 🚀',
      'designHours': 15,
      'devHours': 25,
      'seoCost': 500.0,
      'hostingCost': 150.0,
      'maintenanceCost': 500.0,
      'designDays': 3,
      'devDays': 7,
      'deployDays': 10,
      'scope': [
        'Design focado em conversão',
        'Seção de FAQ & Depoimentos',
        'Integração com gateway de pagamento',
        'Otimização de velocidade e performance',
        'Hospedagem inclusa por 1 ano',
        'Certificado de Segurança SSL ativo',
        'Suporte por 1 mês',
      ],
    },
    {
      'id': 'ecommerce',
      'name': 'E-commerce / Loja Virtual 🛍️',
      'designHours': 60,
      'devHours': 120,
      'seoCost': 2000.0,
      'hostingCost': 600.0,
      'maintenanceCost': 3000.0,
      'designDays': 14,
      'devDays': 30,
      'deployDays': 45,
      'scope': [
        'Design de vitrines e páginas de produto',
        'Carrinho de compras inteligente',
        'Integração com correios e gateways',
        'Painel administrativo completo de vendas',
        'Certificado SSL e segurança LGPD',
        'Hospedagem de alta performance por 1 ano',
        'Suporte & Manutenção por 3 meses',
      ],
    },
    {
      'id': 'mobile_app',
      'name': 'Aplicativo Mobile (iOS & Android) 📱',
      'designHours': 80,
      'devHours': 160,
      'seoCost': 3000.0,
      'hostingCost': 1200.0,
      'maintenanceCost': 6000.0,
      'designDays': 20,
      'devDays': 40,
      'deployDays': 60,
      'scope': [
        'Prototipagem de telas e fluxos UX/UI',
        'Desenvolvimento em Flutter (multiplataforma)',
        'Notificações push automáticas',
        'Integração com banco de dados em nuvem',
        'Publicação oficial nas lojas Apple e Google',
        'Infraestrutura em nuvem inclusa',
        'Manutenção e atualizações por 6 meses',
      ],
    },
    {
      'id': 'branding',
      'name': 'Identidade Visual & Branding 🎨',
      'designHours': 30,
      'devHours': 0,
      'seoCost': 0.0,
      'hostingCost': 0.0,
      'maintenanceCost': 0.0,
      'designDays': 10,
      'devDays': 0,
      'deployDays': 10,
      'scope': [
        'Criação de logotipo principal e variações',
        'Definição de paleta de cores e tipografia',
        'Manual de identidade visual completo',
        'Modelos de papelaria (cartão, pasta, papel)',
        'Templates prontos para redes sociais',
        'Entrega em arquivos vetorizados originais',
      ],
    },
    {
      'id': 'custom',
      'name': 'Outro / Personalizado ⚙️',
      'designHours': 0,
      'devHours': 0,
      'seoCost': 0.0,
      'hostingCost': 0.0,
      'maintenanceCost': 0.0,
      'designDays': 0,
      'devDays': 0,
      'deployDays': 0,
      'scope': <String>[],
    },
  ];

  // Proposal State
  bool _isGenerating = false;
  bool _showResult = false;
  bool _isAiAutoFilling = false;
  int _generationStep = 0;

  // Active Proposal Data
  String _propClient = '';
  String _propProjectName = '';
  String _propProjectType = '';
  String _propCoverLetter = '';
  List<String> _propScope = [];
  int _propDesignHours = 0;
  int _propDevHours = 0;
  double _propSeoCost = 0.0;
  double _propHostingCost = 0.0;
  double _propMaintenanceCost = 0.0;
  int _propDesignDays = 0;
  int _propDevDays = 0;
  int _propDeployDays = 0;
  String _propValidity = '30 dias';
  String _propObservations = 'Este orçamento é válido por 30 dias. Mudanças de escopo implicam em reajuste de preço.';

  String _propFreelancerName = '';
  String _propFreelancerContact = '';
  bool _useMilestones = false;

  String _selectedTheme = 'teal';
  List<Map<String, dynamic>> _savedProposals = [];
  bool _isLoadingSavedProposals = false;
  bool _isSavingProposal = false;

  // Template customization
  Uint8List? _logoImageBytes;
  String _selectedDocStyle = 'moderno'; // 'classico', 'moderno', 'minimalista'

  @override
  void initState() {
    super.initState();
    _applyPresetValues();
    _loadSavedProposals();
  }

  void _loadSavedProposals() async {
    if (mounted) setState(() => _isLoadingSavedProposals = true);
    try {
      final proposalsMap = await _realtimeService.getProposals();
      if (proposalsMap != null) {
        final List<Map<String, dynamic>> temp = [];
        proposalsMap.forEach((key, value) {
          final data = Map<String, dynamic>.from(value as Map);
          data['id'] = key;
          temp.add(data);
        });
        // Sort by date newest first
        temp.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        if (mounted) {
          setState(() {
            _savedProposals = temp;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _savedProposals = [];
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSavedProposals = false);
  }

  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 200,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _logoImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  void _saveProposal() async {
    if (mounted) setState(() => _isSavingProposal = true);
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final data = {
      'clientName': _propClient,
      'projectTitle': _propProjectName,
      'projectType': _propProjectType,
      'coverLetter': _propCoverLetter,
      'designHours': _propDesignHours,
      'devHours': _propDevHours,
      'isFixedPrice': _isFixedPrice,
      'fixedPriceAmount': _fixedPriceAmount,
      'scope': _propScope,
      'designDays': _propDesignDays,
      'devDays': _propDevDays,
      'deployDays': _propDeployDays,
      'seoCost': _propSeoCost,
      'hostingCost': _propHostingCost,
      'maintenanceCost': _propMaintenanceCost,
      'observations': _propObservations,
      'validity': _propValidity,
      'installments': _installments,
      'interestRate': _interestRate,
      'theme': _selectedTheme,
      'freelancerName': _propFreelancerName,
      'freelancerContact': _propFreelancerContact,
      'useMilestones': _useMilestones,
      'selectedDocStyle': _selectedDocStyle,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await _realtimeService.saveProposal(id, data);
      _loadSavedProposals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('💾 Proposta comercial salva com sucesso no banco de dados!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Erro ao salvar proposta: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSavingProposal = false);
  }

  void _loadProposalFromHistory(Map<String, dynamic> proposal) {
    setState(() {
      _clientController.text = proposal['clientName'] ?? '';
      _projectNameController.text = proposal['projectTitle'] ?? '';
      _freelancerNameController.text = proposal['freelancerName'] ?? 'Freelancer Autônomo';
      _freelancerContactController.text = proposal['freelancerContact'] ?? 'contato@empresa.com.br';
      _propClient = proposal['clientName'] ?? '';
      _propProjectName = proposal['projectTitle'] ?? '';
      _propProjectType = proposal['projectType'] ?? '';
      _propCoverLetter = proposal['coverLetter'] ?? '';
      _propDesignHours = proposal['designHours'] ?? 0;
      _propDevHours = proposal['devHours'] ?? 0;
      _isFixedPrice = proposal['isFixedPrice'] ?? false;
      _fixedPriceAmount = (proposal['fixedPriceAmount'] ?? 15000.0).toDouble();
      _propScope = List<String>.from(proposal['scope'] ?? []);
      _propDesignDays = proposal['designDays'] ?? 0;
      _propDevDays = proposal['devDays'] ?? 0;
      _propDeployDays = proposal['deployDays'] ?? 0;
      _propSeoCost = (proposal['seoCost'] ?? 0.0).toDouble();
      _propHostingCost = (proposal['hostingCost'] ?? 0.0).toDouble();
      _propMaintenanceCost = (proposal['maintenanceCost'] ?? 0.0).toDouble();
      _propObservations = proposal['observations'] ?? '';
      _propValidity = proposal['validity'] ?? '30 dias';
      _installments = proposal['installments'] ?? 3;
      _interestRate = (proposal['interestRate'] ?? 0.0).toDouble();
      _selectedTheme = proposal['theme'] ?? 'teal';
      _propFreelancerName = proposal['freelancerName'] ?? 'Freelancer Autônomo';
      _propFreelancerContact = proposal['freelancerContact'] ?? 'contato@empresa.com.br';
      _useMilestones = proposal['useMilestones'] ?? false;
      _selectedDocStyle = proposal['selectedDocStyle'] ?? 'moderno';
      _showResult = true;
    });
  }

  void _deleteProposalFromHistory(String proposalId) async {
    try {
      await _realtimeService.deleteProposal(proposalId);
      _loadSavedProposals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Proposta excluída da nuvem.')),
        );
      }
    } catch (_) {}
  }

  Color get _themePrimaryColor {
    switch (_selectedTheme) {
      case 'dark':
        return const Color(0xFF1E293B);
      case 'blue':
        return const Color(0xFF1D4ED8);
      case 'emerald':
        return const Color(0xFF047857);
      case 'teal':
      default:
        return const Color(0xFF0D9488);
    }
  }

  Color get _themeSecondaryColor {
    switch (_selectedTheme) {
      case 'dark':
        return const Color(0xFFF1F5F9);
      case 'blue':
        return const Color(0xFFDBEAFE);
      case 'emerald':
        return const Color(0xFFD1FAE5);
      case 'teal':
      default:
        return const Color(0xFFCCFBF1);
    }
  }

  Widget _buildThemeButton(String themeId, Color color, String tooltip) {
    final isSelected = _selectedTheme == themeId;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _selectedTheme = themeId),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
                blurRadius: 4,
                spreadRadius: isSelected ? 1 : 0,
              )
            ],
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : null,
        ),
      ),
    );
  }

  void _applyPresetValues() {
    final preset = _presets.firstWhere((p) => p['id'] == _selectedPreset);
    setState(() {
      _projectNameController.text = 'Projeto ${preset['name'].toString().replaceAll(RegExp(r'[^\w\s/&.\-]'), '').trim()}';
      if (_selectedPreset == 'custom') {
        _customPresetNameController.text = 'Serviço Personalizado';
      }
      _propDesignHours = preset['designHours'];
      _propDevHours = preset['devHours'];
      _propSeoCost = preset['seoCost'];
      _propHostingCost = preset['hostingCost'];
      _propMaintenanceCost = preset['maintenanceCost'];
      _propDesignDays = preset['designDays'];
      _propDevDays = preset['devDays'];
      _propDeployDays = preset['deployDays'];
      _propScope = List<String>.from(preset['scope']);
      _propCoverLetter = '';
    });
  }

  // Calculate totals
  double get _designTotal => _isFixedPrice ? 0.0 : _propDesignHours * _designRate;
  double get _devTotal => _isFixedPrice ? 0.0 : _propDevHours * _devRate;
  double get _grandTotal => _isFixedPrice
      ? _fixedPriceAmount + _propSeoCost + _propHostingCost + _propMaintenanceCost
      : _designTotal + _devTotal + _propSeoCost + _propHostingCost + _propMaintenanceCost;

  void _triggerGeneration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isGenerating = true;
      _showResult = false;
      _generationStep = 0;
      _propClient = _clientController.text.trim();
      _propProjectName = _projectNameController.text.trim();
      _propProjectType = _selectedPreset == 'custom'
          ? _customPresetNameController.text.trim()
          : _presets.firstWhere((p) => p['id'] == _selectedPreset)['name'].toString().replaceAll(RegExp(r'[^\w\s/&.\-]'), '').trim();
      _propFreelancerName = _freelancerNameController.text.trim();
      _propFreelancerContact = _freelancerContactController.text.trim();
    });

    // Simulate AI step loading sequence
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _generationStep = i;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _showResult = true;
      });
    }
  }

  void _triggerAiAutoFill() async {
    final clientName = _clientController.text.trim();
    final projectTitle = _projectNameController.text.trim();
    final projectType = _selectedPreset == 'custom'
        ? _customPresetNameController.text.trim()
        : _presets.firstWhere((p) => p['id'] == _selectedPreset)['name'].toString();
    final description = _descriptionController.text.trim();

    if (clientName.isEmpty || projectTitle.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Preencha o Cliente, Título e a Descrição do Projeto na Seção 6 para estimar com IA.')),
      );
      return;
    }

    setState(() => _isAiAutoFilling = true);

    try {
      final estimate = await AiChatService().generateFullProposalEstimate(
        clientName: clientName,
        projectTitle: projectTitle,
        projectType: projectType,
        description: description,
      );

      setState(() {
        _propCoverLetter = estimate['coverLetter'] ?? '';
        _propDesignHours = estimate['designHours'] ?? _propDesignHours;
        _propDevHours = estimate['devHours'] ?? _propDevHours;

        if (_isFixedPrice) {
          _fixedPriceAmount = (estimate['fixedPrice'] ?? _fixedPriceAmount).toDouble();
        }

        _propScope = List<String>.from(estimate['scope'] ?? _propScope);
        _propDesignDays = estimate['designDays'] ?? _propDesignDays;
        _propDevDays = estimate['devDays'] ?? _propDevDays;
        _propDeployDays = estimate['deployDays'] ?? _propDeployDays;
        _propObservations = estimate['observations'] ?? _propObservations;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🤖 Glauber AI estimou prazos, valores, escopo e escreveu a carta de apresentação com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Erro ao estimar com IA: $e')),
      );
    } finally {
      setState(() => _isAiAutoFilling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Auto Proposal Generator ⚡'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  if (!_isGenerating && !_showResult) _buildInputForm(),
                  if (_isGenerating) _buildLoadingAnimation(),
                  if (_showResult) _buildResultView(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Gerar Orçamento Rápido em 30s',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textBody),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nossa IA monta a proposta comercial, estima horas de design, código, plano de pagamento e gera um PDF profissional em segundos.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 28),

              if (_savedProposals.isNotEmpty) ...[
                const Text(
                  '📋 Propostas Recentes (Clique para carregar):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedProposals.length,
                    itemBuilder: (context, index) {
                      final prop = _savedProposals[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          avatar: const Icon(Icons.description, size: 16, color: AppTheme.primary),
                          label: Text(
                            '${prop['clientName']} - ${prop['projectTitle']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _loadProposalFromHistory(prop),
                          onDeleted: () => _deleteProposalFromHistory(prop['id']),
                          deleteIconColor: Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 20),
              ],

              // --- SEÇÃO 1: IDENTIFICAÇÃO E PREÇO ---
              _buildSectionHeader('1. Identificação & Modelo de Preço'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _clientController,
                decoration: AppTheme.inputDecoration('Nome do Cliente ou Empresa', Icons.business),
                validator: (v) => v == null || v.isEmpty ? 'Insira o nome do cliente' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _projectNameController,
                decoration: AppTheme.inputDecoration('Título / Nome do Projeto', Icons.title),
                validator: (v) => v == null || v.isEmpty ? 'Insira o título do projeto' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedPreset,
                decoration: AppTheme.inputDecoration('Tipo de Projeto / Modelo', Icons.assignment_rounded),
                dropdownColor: AppTheme.surface,
                items: _presets.map((preset) {
                  return DropdownMenuItem<String>(
                    value: preset['id'],
                    child: Text(preset['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPreset = val;
                      _applyPresetValues();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_selectedPreset == 'custom') ...[
                TextFormField(
                  controller: _customPresetNameController,
                  decoration: AppTheme.inputDecoration('Nome do Modelo Personalizado', Icons.category),
                  validator: (v) => _selectedPreset == 'custom' && (v == null || v.isEmpty) ? 'Insira a categoria/modelo' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Modelo de Cobrança Selector
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Text('Modelo de Cobrança: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  ChoiceChip(
                    label: const Text('⏰ Por Hora', style: TextStyle(fontSize: 12)),
                    selected: !_isFixedPrice,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(color: !_isFixedPrice ? Colors.white : AppTheme.textBody),
                    onSelected: (val) {
                      if (val) setState(() => _isFixedPrice = false);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('💰 Valor Fixo', style: TextStyle(fontSize: 12)),
                    selected: _isFixedPrice,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(color: _isFixedPrice ? Colors.white : AppTheme.textBody),
                    onSelected: (val) {
                      if (val) setState(() => _isFixedPrice = true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isFixedPrice)
                TextFormField(
                  key: ValueKey('fixed_$_selectedPreset'),
                  initialValue: _fixedPriceAmount.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.inputDecoration('Valor Fixo do Projeto (R\$)', Icons.attach_money),
                  onChanged: (v) => _fixedPriceAmount = double.tryParse(v) ?? 15000.0,
                )
              else ...[
                // Horas e taxas de Design
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('design_hours_$_selectedPreset'),
                        initialValue: _propDesignHours.toString(),
                        keyboardType: TextInputType.number,
                        decoration: AppTheme.inputDecoration('Horas Design', Icons.timer),
                        onChanged: (v) => setState(() => _propDesignHours = int.tryParse(v) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('design_rate_$_selectedPreset'),
                        initialValue: _designRate.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        decoration: AppTheme.inputDecoration('Taxa Design (R\$/h)', Icons.palette),
                        onChanged: (v) => setState(() => _designRate = double.tryParse(v) ?? 100.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Horas e taxas de Dev
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('dev_hours_$_selectedPreset'),
                        initialValue: _propDevHours.toString(),
                        keyboardType: TextInputType.number,
                        decoration: AppTheme.inputDecoration('Horas Dev', Icons.timer),
                        onChanged: (v) => setState(() => _propDevHours = int.tryParse(v) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('dev_rate_$_selectedPreset'),
                        initialValue: _devRate.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        decoration: AppTheme.inputDecoration('Taxa Dev (R\$/h)', Icons.code),
                        onChanged: (v) => setState(() => _devRate = double.tryParse(v) ?? 120.0),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),

              // --- SEÇÃO 2: DADOS DO FREELANCER ---
              _buildSectionHeader('2. Seus Dados (Contato & Assinatura)'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _freelancerNameController,
                decoration: AppTheme.inputDecoration('Seu Nome ou Nome da Empresa', Icons.person),
                validator: (v) => v == null || v.isEmpty ? 'Insira seu nome' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _freelancerContactController,
                decoration: AppTheme.inputDecoration('Seu E-mail ou Telefone de Contato', Icons.contact_mail),
                validator: (v) => v == null || v.isEmpty ? 'Insira seu e-mail/contato' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.image_outlined, size: 20),
                      label: Text(
                        _logoImageBytes == null ? 'Fazer Upload de Logo 📁' : 'Logo Carregada ✓ (Alterar)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  if (_logoImageBytes != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: MemoryImage(_logoImageBytes!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _logoImageBytes = null;
                        });
                      },
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Estilo Visual do Documento (PDF):',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDocStyle,
                decoration: AppTheme.inputDecoration('Estilo da Proposta', Icons.text_fields_outlined),
                dropdownColor: AppTheme.surface,
                items: const [
                  DropdownMenuItem(value: 'classico', child: Text('📋 Clássico (Formal, Serif)')),
                  DropdownMenuItem(value: 'moderno', child: Text('⚡ Moderno (Cantos arredondados, Sans)')),
                  DropdownMenuItem(value: 'minimalista', child: Text('🌿 Minimalista (Limpo, Espaçado)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDocStyle = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              const Divider(),

              // --- SEÇÃO 3: ESCOPO ---
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('3. Escopo do Projeto (Itens)'),
                  _isGeneratingScope
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        )
                      : TextButton.icon(
                          onPressed: () async {
                            final String currentDesc = _descriptionController.text.trim();
                            if (currentDesc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('⚠️ Preencha a Descrição do Projeto (Seção 5) primeiro para a IA entender o contexto.')),
                              );
                              return;
                            }
                            setState(() => _isGeneratingScope = true);
                            try {
                              final items = await AiChatService().generateScopeFromDescription(currentDesc);
                              if (items.isNotEmpty) {
                                setState(() {
                                  _propScope = items;
                                });
                              }
                            } catch (_) {}
                            setState(() => _isGeneratingScope = false);
                          },
                          icon: const Icon(Icons.psychology_outlined, size: 14, color: AppTheme.primary),
                          label: const Text('Escrever com IA 🤖', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _scopeItemController,
                      decoration: AppTheme.inputDecoration('Adicionar item ao escopo', Icons.add_task),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_scopeItemController.text.trim().isNotEmpty) {
                          setState(() {
                            _propScope.add(_scopeItemController.text.trim());
                            _scopeItemController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Listagem de itens do escopo atuais com delete
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: _propScope.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('Nenhum item no escopo. Adicione acima.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _propScope.length,
                        itemBuilder: (context, idx) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 16),
                            title: Text(_propScope[idx], style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                              onPressed: () {
                                setState(() {
                                  _propScope.removeAt(idx);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 32),
              const Divider(),

              // --- SEÇÃO 4: CRONOGRAMA ---
              const SizedBox(height: 16),
              _buildSectionHeader('4. Cronograma de Entrega (Dias Úteis)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('design_days_$_selectedPreset'),
                      initialValue: _propDesignDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Dias Design', Icons.calendar_today),
                      onChanged: (v) => _propDesignDays = int.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('dev_days_$_selectedPreset'),
                      initialValue: _propDevDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Dias Dev', Icons.calendar_today),
                      onChanged: (v) => _propDevDays = int.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('deploy_days_$_selectedPreset'),
                      initialValue: _propDeployDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Dias Deploy', Icons.calendar_today),
                      onChanged: (v) => _propDeployDays = int.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),

              // --- SEÇÃO 5: OUTROS CUSTOS ---
              const SizedBox(height: 16),
              _buildSectionHeader('5. Condições & Outros Custos (Opcionais)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('seo_cost_$_selectedPreset'),
                      initialValue: _propSeoCost.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('SEO (R\$)', Icons.search),
                      onChanged: (v) => _propSeoCost = double.tryParse(v) ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('hosting_cost_$_selectedPreset'),
                      initialValue: _propHostingCost.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Hospedagem (R\$)', Icons.dns),
                      onChanged: (v) => _propHostingCost = double.tryParse(v) ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('maint_cost_$_selectedPreset'),
                      initialValue: _propMaintenanceCost.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration('Suporte (R\$)', Icons.support_agent),
                      onChanged: (v) => _propMaintenanceCost = double.tryParse(v) ?? 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),

              // --- SEÇÃO 6: DESCRIÇÃO GERAL ---
              const SizedBox(height: 16),
              _buildSectionHeader('6. Descrição do Projeto (Contexto)'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: AppTheme.inputDecoration('Descrição Geral do Projeto', Icons.description),
              ),
              const SizedBox(height: 32),

              // Submit Button
              // AI Auto-fill Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isAiAutoFilling ? null : _triggerAiAutoFill,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isAiAutoFilling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      const SizedBox(width: 12),
                      const Text(
                        'Auto-Preencher & Estimar com Glauber AI 🤖',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _triggerGeneration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Gerar Proposta Comercial 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary, letterSpacing: 0.5),
    );
  }

  Widget _buildLoadingAnimation() {
    final List<String> stepsText = [
      'Analisando requisitos do projeto...',
      'Estimando escopo e horas necessárias...',
      'Calculando custos operacionais e margem...',
      'Montando proposta comercial e PDF...',
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Gerando Proposta Comercial...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: List.generate(stepsText.length, (idx) {
                  final isDone = idx < _generationStep;
                  final isCurrent = idx == _generationStep;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : (isCurrent ? Icons.sync : Icons.radio_button_unchecked),
                          color: isDone ? Colors.green : (isCurrent ? AppTheme.primary : AppTheme.textMuted),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stepsText[idx],
                            style: TextStyle(
                              color: isDone ? AppTheme.textBody : (isCurrent ? AppTheme.primary : AppTheme.textMuted),
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Column(
      children: [
        // Action top bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showResult = false;
                });
              },
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              label: const Text('Refazer Orçamento', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            Row(
              children: [
                IconButton(
                  icon: _isSavingProposal
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : const Icon(Icons.save, color: AppTheme.primary),
                  tooltip: 'Salvar Proposta na Nuvem',
                  onPressed: _isSavingProposal ? null : _saveProposal,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                  tooltip: 'Editar Valores',
                  onPressed: _showEditBottomSheet,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.green),
                  tooltip: 'Enviar via WhatsApp',
                  onPressed: _shareOnWhatsApp,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  tooltip: 'Exportar PDF',
                  onPressed: _exportProposalPdf,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Theme selector buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tema da Proposta: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _buildThemeButton('teal', const Color(0xFF0D9488), 'Teal'),
            const SizedBox(width: 8),
            _buildThemeButton('emerald', const Color(0xFF047857), 'Esmeralda'),
            const SizedBox(width: 8),
            _buildThemeButton('blue', const Color(0xFF1D4ED8), 'Azul'),
            const SizedBox(width: 8),
            _buildThemeButton('dark', const Color(0xFF1E293B), 'Grafite'),
          ],
        ),
        const SizedBox(height: 16),

        // Proposal Canvas Sheet
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Proposal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _logoImageBytes != null
                            ? Container(
                                height: 44,
                                width: 100,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: MemoryImage(_logoImageBytes!),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _themePrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.analytics_rounded, color: _themePrimaryColor, size: 36),
                              ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORÇAMENTO COMERCIAL',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _themePrimaryColor, letterSpacing: 0.5),
                            ),
                            const Text('GerePag - Auto Proposal Generator', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Data: $formattedDate', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text('Validade: $_propValidity', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Info Section
                Row(
                  children: [
                    const Text('CLIENTE: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody, fontSize: 14)),
                    Text(_propClient, style: const TextStyle(color: AppTheme.textBody, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('PROJETO: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody, fontSize: 14)),
                    Text(_propProjectName, style: const TextStyle(color: AppTheme.textBody, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('TIPO / MODELO: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody, fontSize: 14)),
                    Text(_propProjectType, style: const TextStyle(color: AppTheme.textBody, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 24),
                if (_propCoverLetter.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _themePrimaryColor.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: _themePrimaryColor, width: 4)),
                    ),
                    child: Text(
                      _propCoverLetter,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textBody,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 24),

                // Escopo / Scope Checklist
                Text('ESCOPO DO PROJETO', style: TextStyle(fontWeight: FontWeight.bold, color: _themePrimaryColor, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 16),
                if (_propScope.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Nenhum item no escopo. Adicione abaixo.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  )
                else
                  ..._propScope.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textBody, height: 1.4),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _propScope.remove(item);
                                });
                              },
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newScopeItemController,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Adicionar novo item de escopo ao vivo...',
                          hintStyle: TextStyle(fontSize: 12),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (v) {
                          final text = v.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _propScope.add(text);
                              _newScopeItemController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final text = _newScopeItemController.text.trim();
                        if (text.isNotEmpty) {
                          setState(() {
                            _propScope.add(text);
                            _newScopeItemController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Costs breakdown table
                Text('METRIFICAÇÃO DE CUSTOS', style: TextStyle(fontWeight: FontWeight.bold, color: _themePrimaryColor, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 16),
                if (_isFixedPrice)
                  _buildCostRow('Desenvolvimento & Design', 'Preço Fechado', currency.format(_fixedPriceAmount))
                else ...[
                  _buildCostRow('Design e Interface', '$_propDesignHours h × ${currency.format(_designRate)}', currency.format(_designTotal)),
                  _buildCostRow('Desenvolvimento e Integrações', '$_propDevHours h × ${currency.format(_devRate)}', currency.format(_devTotal)),
                ],
                if (_propSeoCost > 0) _buildCostRow('SEO & Otimizações', 'Serviço pontual', currency.format(_propSeoCost)),
                if (_propHostingCost > 0) _buildCostRow('Hospedagem + SSL (Anual)', 'Infraestrutura', currency.format(_propHostingCost)),
                if (_propMaintenanceCost > 0) _buildCostRow('Suporte & Manutenção', 'Mensal (3 meses)', currency.format(_propMaintenanceCost)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _themePrimaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('VALOR TOTAL DO INVESTIMENTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _themePrimaryColor)),
                      Text(currency.format(_grandTotal), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _themePrimaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Simulador de Parcelamento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _themePrimaryColor.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _themePrimaryColor.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calculate_outlined, color: _themePrimaryColor, size: 18),
                              const SizedBox(width: 8),
                              Text('Forma de Pagamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _themePrimaryColor)),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('⏰ Parcelas', style: TextStyle(fontSize: 10)),
                                selected: !_useMilestones,
                                selectedColor: _themePrimaryColor,
                                labelStyle: TextStyle(color: !_useMilestones ? Colors.white : AppTheme.textBody),
                                onSelected: (val) {
                                  if (val) setState(() => _useMilestones = false);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('📆 Marcos', style: TextStyle(fontSize: 10)),
                                selected: _useMilestones,
                                selectedColor: _themePrimaryColor,
                                labelStyle: TextStyle(color: _useMilestones ? Colors.white : AppTheme.textBody),
                                onSelected: (val) {
                                  if (val) setState(() => _useMilestones = true);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_useMilestones) ...[
                        const SizedBox(height: 16),
                        _buildMilestoneRow('1. Kickoff / Início do Projeto (40%)', _grandTotal * 0.40),
                        const SizedBox(height: 8),
                        _buildMilestoneRow('2. Aprovação do Design & Protótipo (30%)', _grandTotal * 0.30),
                        const SizedBox(height: 8),
                        _buildMilestoneRow('3. Entrega, Homologação & Deploy Final (30%)', _grandTotal * 0.30),
                      ] else ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: (_installments ?? 3),
                                decoration: AppTheme.inputDecoration('Parcelas', Icons.format_list_numbered),
                                dropdownColor: AppTheme.surface,
                                items: List.generate(12, (index) => index + 1).map((i) {
                                  return DropdownMenuItem<int>(
                                    value: i,
                                    child: Text('$i x'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _installments = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: (_interestRate ?? 0.0).toStringAsFixed(1),
                                keyboardType: TextInputType.number,
                                decoration: AppTheme.inputDecoration('Juros Mensal (%)', Icons.percent),
                                onChanged: (v) => setState(() => _interestRate = double.tryParse(v) ?? 0.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Payments and terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONDIÇÕES DE PAGAMENTO', style: TextStyle(fontWeight: FontWeight.bold, color: _themePrimaryColor, fontSize: 12)),
                          const SizedBox(height: 12),
                          _buildPaymentBullet('À vista (5% desc): ${currency.format(_grandTotal * 0.95)}'),
                          if ((_installments ?? 3) > 1) ...[
                            if ((_interestRate ?? 0.0) == 0)
                              _buildPaymentBullet('${_installments ?? 3}x sem juros: ${currency.format(_grandTotal / (_installments ?? 3))} / mês')
                            else (() {
                              final simpleTotal = _grandTotal * (1 + ((_interestRate ?? 0.0) / 100) * (_installments ?? 3));
                              final simplePmt = simpleTotal / (_installments ?? 3);
                              return _buildPaymentBullet('${_installments ?? 3}x de ${currency.format(simplePmt)} (${_interestRate ?? 0.0}% juros/mês)');
                            }())
                          ] else
                            _buildPaymentBullet('1 parcela única de ${currency.format(_grandTotal)}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CRONOGRAMA DE ENTREGAS', style: TextStyle(fontWeight: FontWeight.bold, color: _themePrimaryColor, fontSize: 12)),
                          const SizedBox(height: 12),
                          _buildTimelineBullet('Etapa Design', '$_propDesignDays dias'),
                          _buildTimelineBullet('Etapa Desenvolvimento', '$_propDevDays dias'),
                          _buildTimelineBullet('Implantação/Deploy', '$_propDeployDays dias'),
                          _buildTimelineBullet('Prazo Final Otimizado', '${_propDesignDays + _propDevDays + _propDeployDays} dias'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildGanttChartWidget(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Observations
                const Text('OBSERVAÇÕES GERAIS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 8),
                Text(
                  _propObservations,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic, height: 1.4),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Contatos e Assinaturas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROPOSTO POR:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(_propFreelancerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textBody)),
                          Text(_propFreelancerContact, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('PARA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(_propClient.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textBody)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 1,
                            color: AppTheme.textMuted.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          const Text('Assinatura do Contratante', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 1,
                            color: AppTheme.textMuted.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          const Text('Assinatura do Contratado', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Action Panel
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _linkToKanban,
                icon: const Icon(Icons.view_kanban_rounded, color: Colors.white),
                label: const Text('Vincular ao Kanban / Criar Projeto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareOnWhatsApp,
                    icon: const Icon(Icons.message, color: Colors.green),
                    label: const Text('Enviar WhatsApp', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareViaEmail,
                    icon: const Icon(Icons.email_outlined, color: Colors.blue),
                    label: const Text('Enviar por E-mail', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostRow(String title, String details, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
              Text(details, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        ],
      ),
    );
  }

  Widget _buildPaymentBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.credit_card_rounded, color: _themePrimaryColor, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textBody))),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(String label, double value) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          currency.format(value),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textBody),
        ),
      ],
    );
  }

  Widget _buildTimelineBullet(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        ],
      ),
    );
  }

  Widget _buildGanttChartWidget() {
    final totalDays = _propDesignDays + _propDevDays + _propDeployDays;
    if (totalDays == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRONOGRAMA VISUAL DE FASES (GANTT)',
          style: TextStyle(fontWeight: FontWeight.bold, color: _themePrimaryColor, fontSize: 11, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
            ),
            child: Row(
              children: [
                if (_propDesignDays > 0)
                  Expanded(
                    flex: _propDesignDays,
                    child: Container(
                      color: Colors.blue.shade400,
                      child: Center(
                        child: Text(
                          'Design (${_propDesignDays}d)',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                if (_propDevDays > 0)
                  Expanded(
                    flex: _propDevDays,
                    child: Container(
                      color: Colors.purple.shade400,
                      child: Center(
                        child: Text(
                          'Dev (${_propDevDays}d)',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                if (_propDeployDays > 0)
                  Expanded(
                    flex: _propDeployDays,
                    child: Container(
                      color: Colors.green.shade400,
                      child: Center(
                        child: Text(
                          'Deploy (${_propDeployDays}d)',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dia 0', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            Text('Prazo Final Otimizado: $totalDays dias úteis', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showEditBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Editar Detalhes da Proposta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hours
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _propDesignHours.toString(),
                            keyboardType: TextInputType.number,
                            decoration: AppTheme.inputDecoration('Horas Design', Icons.palette),
                            onChanged: (v) {
                              setModalState(() => _propDesignHours = int.tryParse(v) ?? _propDesignHours);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _propDevHours.toString(),
                            keyboardType: TextInputType.number,
                            decoration: AppTheme.inputDecoration('Horas Dev', Icons.code),
                            onChanged: (v) {
                              setModalState(() => _propDevHours = int.tryParse(v) ?? _propDevHours);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Extra costs
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _propSeoCost.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: AppTheme.inputDecoration('SEO Cost (R\$)', Icons.trending_up),
                            onChanged: (v) {
                              setModalState(() => _propSeoCost = double.tryParse(v) ?? _propSeoCost);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _propHostingCost.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: AppTheme.inputDecoration('Hospedagem (R\$)', Icons.cloud),
                            onChanged: (v) {
                              setModalState(() => _propHostingCost = double.tryParse(v) ?? _propHostingCost);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Project Validity & Observations
                    TextFormField(
                      initialValue: _propValidity,
                      decoration: AppTheme.inputDecoration('Validade do Orçamento', Icons.date_range),
                      onChanged: (v) {
                        setModalState(() => _propValidity = v);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: _propObservations,
                      maxLines: 2,
                      decoration: AppTheme.inputDecoration('Observações Gerais', Icons.info_outline),
                      onChanged: (v) {
                        setModalState(() => _propObservations = v);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Aplicar Ajustes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _shareOnWhatsApp() async {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final String costLines;
    if (_isFixedPrice) {
      costLines = '• Desenvolvimento & Design: Preço Fechado -> ${currency.format(_fixedPriceAmount)}\n';
    } else {
      costLines = '• Design: ${_propDesignHours}h -> ${currency.format(_designTotal)}\n'
          '• Dev: ${_propDevHours}h -> ${currency.format(_devTotal)}\n';
    }

    final String paymentLines;
    if ((_installments ?? 3) > 1) {
      if ((_interestRate ?? 0.0) == 0) {
        paymentLines = '• À vista com desconto (5%): ${currency.format(_grandTotal * 0.95)}\n'
            '• ${_installments ?? 3}x sem juros: ${currency.format(_grandTotal / (_installments ?? 3))} / mês\n';
      } else {
        final simpleTotal = _grandTotal * (1 + ((_interestRate ?? 0.0) / 100) * (_installments ?? 3));
        final simplePmt = simpleTotal / (_installments ?? 3);
        paymentLines = '• À vista com desconto (5%): ${currency.format(_grandTotal * 0.95)}\n'
            '• ${_installments ?? 3}x de: ${currency.format(simplePmt)} / mês (com ${_interestRate ?? 0.0}% juros/mês)\n';
      }
    } else {
      paymentLines = '• À vista com desconto (5%): ${currency.format(_grandTotal * 0.95)}\n'
          '• 1 parcela única de: ${currency.format(_grandTotal)}\n';
    }

    final String message = '*📊 PROPOSTA COMERCIAL GERADA*\n'
        '--------------------------------------------\n'
        '*CLIENTE:* $_propClient\n'
        '*PROJETO:* $_propProjectName\n'
        '*DATA:* $formattedDate\n'
        '*VALIDADE:* $_propValidity\n'
        '--------------------------------------------\n'
        '*CUSTOS DETALHADOS:*\n'
        '$costLines'
        '${_propSeoCost > 0 ? '• SEO: ${currency.format(_propSeoCost)}\n' : ''}'
        '${_propHostingCost > 0 ? '• Hospedagem: ${currency.format(_propHostingCost)}\n' : ''}'
        '${_propMaintenanceCost > 0 ? '• Manutenção: ${currency.format(_propMaintenanceCost)}\n' : ''}'
        '--------------------------------------------\n'
        '*INVESTIMENTO TOTAL:* *${currency.format(_grandTotal)}*\n'
        '--------------------------------------------\n'
        '*PAGAMENTO:*\n'
        '$paymentLines'
        '--------------------------------------------\n'
        '*PRAZOS:*\n'
        '• Design: $_propDesignDays dias\n'
        '• Dev: $_propDevDays dias\n'
        '• Deploy: $_propDeployDays dias\n'
        '• Total: ${_propDesignDays + _propDevDays + _propDeployDays} dias\n'
        '--------------------------------------------\n'
        '*OBSERVAÇÕES:*\n'
        '_\"$_propObservations\"_\n';

    final encodedText = Uri.encodeComponent(message);
    final url = 'https://wa.me/?text=$encodedText';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copiado para a Área de Transferência (WhatsApp não instalado)!')),
        );
      }
    }
  }

  void _shareViaEmail() async {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final totalDays = _propDesignDays + _propDevDays + _propDeployDays;

    final String costLines;
    if (_isFixedPrice) {
      costLines = '• Desenvolvimento & Design: Preço Fechado -> ${currency.format(_fixedPriceAmount)}\n';
    } else {
      costLines = '• Design: ${_propDesignHours}h -> ${currency.format(_designTotal)}\n'
          '• Dev: ${_propDevHours}h -> ${currency.format(_devTotal)}\n';
    }

    final String paymentLines;
    if (_useMilestones) {
      paymentLines = '• Kickoff / Entrada (40%): ${currency.format(_grandTotal * 0.40)}\n'
          '• Aprovação do Design (30%): ${currency.format(_grandTotal * 0.30)}\n'
          '• Entrega Final / Deploy (30%): ${currency.format(_grandTotal * 0.30)}\n';
    } else if ((_installments ?? 3) > 1) {
      if ((_interestRate ?? 0.0) == 0) {
        paymentLines = '• À vista com desconto (5%): ${currency.format(_grandTotal * 0.95)}\n'
            '• ${_installments ?? 3}x sem juros: ${currency.format(_grandTotal / (_installments ?? 3))} / mês\n';
      } else {
        final simpleTotal = _grandTotal * (1 + ((_interestRate ?? 0.0) / 100) * (_installments ?? 3));
        final simplePmt = simpleTotal / (_installments ?? 3);
        paymentLines = '• À vista com desconto (5%): ${currency.format(_grandTotal * 0.95)}\n'
            '• ${_installments ?? 3}x de: ${currency.format(simplePmt)} / mês (com ${_interestRate ?? 0.0}% juros/mês)\n';
      }
    } else {
      paymentLines = '• À vista com desconto (5%): ${currency.format(_grandTotal * 0.95)}\n'
          '• 1 parcela única de: ${currency.format(_grandTotal)}\n';
    }

    // Construct email body using StringBuffer for clarity and proper interpolation
    final StringBuffer body = StringBuffer();
    body.writeln('Olá $_propClient,\n');
    body.writeln('Segue abaixo o detalhamento da proposta comercial para o projeto "$_propProjectName" ($_propProjectType).\n');
    body.writeln('--- RESUMO DO ESCOPO ---\n${_propScope.map((item) => '- $item').join('\n')}\n');
    body.writeln('--- DETALHES DE INVESTIMENTO ---\n$costLines');
    if (_propSeoCost > 0) body.writeln('• SEO: ${currency.format(_propSeoCost)}\n');
    if (_propHostingCost > 0) body.writeln('• Hospedagem: ${currency.format(_propHostingCost)}\n');
    if (_propMaintenanceCost > 0) body.writeln('• Manutenção: ${currency.format(_propMaintenanceCost)}\n');
    body.writeln('TOTAL: ${currency.format(_grandTotal)}\n\n');
    body.writeln('--- CONDIÇÕES DE PAGAMENTO ---\n$paymentLines');
    body.writeln('--- CRONOGRAMA DE ENTREGAS ---\n• Design: $_propDesignDays dias\n• Dev: $_propDevDays dias\n• Deploy: $_propDeployDays dias\nPrazo Total Estimado: $totalDays dias úteis\n\n');
    body.writeln('--- OBSERVAÇÕES ---\n$_propObservations\n\n');
    body.writeln('Atenciosamente,\n$_propFreelancerName\n$_propFreelancerContact');

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Proposta Comercial - $_propProjectName',
        'body': body.toString(),
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Não foi possível abrir o cliente de e-mail.';
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: body.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copiei o conteúdo da proposta para a área de transferência! Cole no seu cliente de e-mail. 📬📋'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    }
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _exportProposalPdf() async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final pdfPrimaryColor = _selectedTheme == 'dark'
        ? PdfColors.grey800
        : _selectedTheme == 'blue'
            ? PdfColors.blue700
            : _selectedTheme == 'emerald'
                ? PdfColors.green700
                : PdfColors.teal700;

    final font = _selectedDocStyle == 'classico'
        ? pw.Font.times()
        : _selectedDocStyle == 'minimalista'
            ? pw.Font.courier()
            : pw.Font.helvetica();

    final fontBold = _selectedDocStyle == 'classico'
        ? pw.Font.timesBold()
        : _selectedDocStyle == 'minimalista'
            ? pw.Font.courierBold()
            : pw.Font.helveticaBold();

    final fontItalic = _selectedDocStyle == 'classico'
        ? pw.Font.timesItalic()
        : _selectedDocStyle == 'minimalista'
            ? pw.Font.courierOblique()
            : pw.Font.helveticaOblique();

    final pdfTheme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: fontItalic,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pdfTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (_logoImageBytes != null) ...[
                        pw.Image(
                          pw.MemoryImage(_logoImageBytes!),
                          height: 28,
                        ),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Text(
                        _logoImageBytes != null ? 'PROPOSTA COMERCIAL' : 'GEREPAGUE - PROPOSTA COMERCIAL',
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: pdfPrimaryColor),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Data: $formattedDate', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Validade: $_propValidity', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Info
              pw.Text('CLIENTE: $_propClient', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('PROJETO: $_propProjectName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('TIPO / MODELO: $_propProjectType', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              if (_propCoverLetter.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border(left: pw.BorderSide(color: pdfPrimaryColor, width: 3)),
                  ),
                  child: pw.Text(
                    _propCoverLetter,
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Scope
              pw.Text('ESCOPO DETALHADO:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimaryColor)),
              pw.SizedBox(height: 8),
              ..._propScope.map((item) => pw.Bullet(text: item, style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 24),

              // Values table
              pw.Text('METRIFICAÇÃO DE INVESTIMENTOS:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfPrimaryColor)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                data: [
                  ['Serviço', 'Unidades / Horas', 'Subtotal'],
                  if (_isFixedPrice)
                    ['Desenvolvimento & Design', 'Preço Fechado', currency.format(_fixedPriceAmount)]
                  else ...[
                    ['Design & UI/UX', '$_propDesignHours h', currency.format(_designTotal)],
                    ['Desenvolvimento & Código', '$_propDevHours h', currency.format(_devTotal)],
                  ],
                  if (_propSeoCost > 0) ['SEO & Otimizações', 'Pontual', currency.format(_propSeoCost)],
                  if (_propHostingCost > 0) ['Hospedagem & Certificados', '1 Ano', currency.format(_propHostingCost)],
                  if (_propMaintenanceCost > 0) ['Suporte Técnico', '3 Meses', currency.format(_propMaintenanceCost)],
                  ['INVESTIMENTO TOTAL', '', currency.format(_grandTotal)],
                ],
              ),
              pw.SizedBox(height: 24),

              // Payment options & deadlines
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CONDIÇÕES DE PAGAMENTO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdfPrimaryColor)),
                        pw.SizedBox(height: 6),
                        if (_useMilestones) ...[
                          pw.Text('• Entrada / Kickoff (40%): ${currency.format(_grandTotal * 0.40)}', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('• Aprovação de Protótipo (30%): ${currency.format(_grandTotal * 0.30)}', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('• Entrega Final / Deploy (30%): ${currency.format(_grandTotal * 0.30)}', style: const pw.TextStyle(fontSize: 8)),
                        ] else ...[
                          pw.Text('• À vista (5% desc): ${currency.format(_grandTotal * 0.95)}', style: const pw.TextStyle(fontSize: 9)),
                          if ((_installments ?? 3) > 1)
                            if ((_interestRate ?? 0.0) == 0)
                              pw.Text('• ${_installments ?? 3}x sem juros: ${currency.format(_grandTotal / (_installments ?? 3))} / mês', style: const pw.TextStyle(fontSize: 9))
                            else (() {
                              final simpleTotal = _grandTotal * (1 + ((_interestRate ?? 0.0) / 100) * (_installments ?? 3));
                              final simplePmt = simpleTotal / (_installments ?? 3);
                              return pw.Text('• ${_installments ?? 3}x de ${currency.format(simplePmt)} / mês (${_interestRate ?? 0.0}% juros/mês)', style: const pw.TextStyle(fontSize: 9));
                            }())
                          else
                            pw.Text('• 1 parcela única de ${currency.format(_grandTotal)}', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CRONOGRAMA DE IMPLANTAÇÃO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdfPrimaryColor)),
                        pw.SizedBox(height: 6),
                        pw.Text('• Design: $_propDesignDays dias', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('• Desenvolvimento: $_propDevDays dias', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('• Deploy Final: $_propDeployDays dias', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              // Gantt Chart in PDF
              if (_propDesignDays + _propDevDays + _propDeployDays > 0) ...[
                pw.SizedBox(height: 20),
                pw.Text('CRONOGRAMA VISUAL DE FASES (GANTT)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: pdfPrimaryColor)),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 16,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      if (_propDesignDays > 0)
                        pw.Expanded(
                          flex: _propDesignDays,
                          child: pw.Container(
                            color: PdfColors.blue300,
                            child: pw.Center(
                              child: pw.Text(
                                'Design (${_propDesignDays}d)',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      if (_propDevDays > 0)
                        pw.Expanded(
                          flex: _propDevDays,
                          child: pw.Container(
                            color: PdfColors.purple300,
                            child: pw.Center(
                              child: pw.Text(
                                'Dev (${_propDevDays}d)',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      if (_propDeployDays > 0)
                        pw.Expanded(
                          flex: _propDeployDays,
                          child: pw.Container(
                            color: PdfColors.green300,
                            child: pw.Center(
                              child: pw.Text(
                                'Deploy (${_propDeployDays}d)',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Observations
              pw.Text('OBSERVAÇÕES: $_propObservations', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
              pw.SizedBox(height: 32),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Contatos e Assinaturas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PROPOSTO POR:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(_propFreelancerName.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_propFreelancerContact, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PARA:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(_propClient.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 48),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(height: 0.5, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Text('Assinatura do Contratante', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 48),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(height: 0.5, color: PdfColors.grey400),
                        pw.SizedBox(height: 4),
                        pw.Text('Assinatura do Contratado', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'proposta_${_propClient.replaceAll(RegExp(r'\s+'), '_')}.pdf',
    );
  }

  void _linkToKanban() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, faça login para salvar no Kanban.')),
      );
      return;
    }

    try {
      final databaseRef = FirebaseDatabase.instance.ref('users/$uid/local_services').push();
      final String serviceId = databaseRef.key!;

      final Map<String, dynamic> serviceMap = {
        'clientName': _propClient,
        'description': 'PROPOSTA AUTOMÁTICA: $_propProjectName. Inclui escopo: ${_propScope.join(", ")}',
        'amount': _grandTotal.toStringAsFixed(2),
        'cost': '0.00',
        'dueDate': DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30))),
        'status': 'todo', // starts at Pennding/Todo Kanban column
        'createdAt': ServerValue.timestamp,
      };

      await _realtimeService.saveLocalService(serviceId, serviceMap);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projeto vinculado ao Kanban com sucesso! 📋🚀'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar no Kanban: $e')),
        );
      }
    }
  }
}
