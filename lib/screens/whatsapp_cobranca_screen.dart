import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../services/ai_chat_service.dart';
import '../services/realtime_db_service.dart';

class WhatsAppCobrancaScreen extends StatefulWidget {
  final String? initialClientName;
  final double? initialAmount;
  final String? initialDescription;

  const WhatsAppCobrancaScreen({
    super.key,
    this.initialClientName,
    this.initialAmount,
    this.initialDescription,
  });

  @override
  State<WhatsAppCobrancaScreen> createState() => _WhatsAppCobrancaScreenState();
}

class _WhatsAppCobrancaScreenState extends State<WhatsAppCobrancaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aiChatService = AiChatService();

  final _clientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 5));
  String _selectedTone = 'amigavel';
  String _generatedText = '';
  bool _isLoading = false;
  String? _selectedLocalClientId;

  final Map<String, String> _tones = {
    'amigavel': 'Amigável (Polido & Empático) 😊',
    'profissional': 'Profissional (Formal & Direto) 💼',
    'urgente': 'Urgente (Vencido & Assertivo) ⚠️',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialClientName != null) {
      _clientNameController.text = widget.initialClientName!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialDescription != null) {
      _descController.text = widget.initialDescription!;
    }
    _loadPixKey();
  }

  String _pixKey = '';
  void _loadPixKey() async {
    try {
      final key = await RealtimeDbService().getPixKey().first;
      if (mounted) {
        setState(() {
          _pixKey = key;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: AppTheme.textBody,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _generateMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedText = '';
    });

    final name = _clientNameController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final dueDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final desc = _descController.text.trim().isEmpty ? 'serviços prestados' : _descController.text.trim();

    // Customizar prompt baseado no tom
    String tonePrompt = '';
    if (_selectedTone == 'amigavel') {
      tonePrompt = 'Escreva com tom extremamente amigável, acolhedor e gentil.';
    } else if (_selectedTone == 'profissional') {
      tonePrompt = 'Escreva com tom extremamente profissional, elegante, polido e corporativo.';
    } else {
      tonePrompt = 'Escreva com tom assertivo, lembrando educadamente que a fatura já está vencida ou prestes a vencer, sendo direto, mas sem perder a classe.';
    }

    try {
      final String fullDesc = '$desc ($tonePrompt)';
      final baseText = await _aiChatService.generateNegotiationProposal(
        contactName: name,
        amount: amount,
        dueDate: dueDate,
        description: fullDesc,
        type: 'receber',
      );

      // Para manter a assinatura padrão do Glauber
      String cleanText = baseText
          .replaceAll(RegExp(r'\[Instrução de Tom:.*?\]'), '')
          .trim();

      if (_pixKey.isNotEmpty) {
        cleanText += '\n\n🔑 Chave Pix para pagamento:\n$_pixKey';
      }

      setState(() {
        _generatedText = cleanText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _generatedText = 'Erro ao gerar mensagem por IA. Tente novamente.\nErro: $e';
        _isLoading = false;
      });
    }
  }

  void _sendViaWhatsApp() async {
    if (_generatedText.isEmpty) return;

    final String rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o telefone celular do cliente.')),
      );
      return;
    }

    // Se o número tem 10 ou 11 dígitos, acrescenta o DDI 55 (Brasil)
    final String formattedPhone = (rawPhone.length == 10 || rawPhone.length == 11)
        ? '55$rawPhone'
        : rawPhone;

    final url = 'https://api.whatsapp.com/send?phone=$formattedPhone&text=${Uri.encodeComponent(_generatedText)}';
    
    try {
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abrindo conversa do WhatsApp...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp. Tentando abrir no navegador...')),
        );
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir o WhatsApp: $e')),
      );
    }
  }

  void _sendViaEmail() async {
    if (_generatedText.isEmpty) return;

    final String email = _emailController.text.trim();
    final String subject = 'Cobrança - GEREPAGUE';
    
    final url = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(_generatedText)}';
    
    try {
      final uri = Uri.parse(url);
      if (await launchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abrindo seu aplicativo de e-mail...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o aplicativo de e-mail.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar e-mail: $e')),
      );
    }
  }

  void _copyToClipboard() {
    if (_generatedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensagem copiada para a área de transferência! 📋'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Cobrança por WhatsApp 💬',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DADOS DO CLIENTE & COBRANÇA',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: RealtimeDbService().getLocalClients(),
                      builder: (context, snapshot) {
                        final localClients = snapshot.data ?? [];
                        if (localClients.isEmpty) return const SizedBox.shrink();

                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              dropdownColor: AppTheme.surface,
                              value: _selectedLocalClientId,
                              style: const TextStyle(color: AppTheme.textBody),
                              decoration: const InputDecoration(
                                labelText: 'Autopreencher com Cliente Salvo 👥',
                                labelStyle: TextStyle(color: AppTheme.textMuted),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Preencher manualmente...'),
                                ),
                                ...localClients.map((client) {
                                  return DropdownMenuItem(
                                    value: client['id'],
                                    child: Text(client['name'] ?? ''),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedLocalClientId = val;
                                  if (val != null) {
                                    final client = localClients.firstWhere((c) => c['id'] == val);
                                    _clientNameController.text = client['name'] ?? '';
                                    _phoneController.text = client['phone'] ?? '';
                                    _emailController.text = client['email'] ?? '';
                                  } else {
                                    _clientNameController.clear();
                                    _phoneController.clear();
                                    _emailController.clear();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                    TextFormField(
                      controller: _clientNameController,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Nome do Cliente',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'Ex: João da Silva',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do cliente' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Celular / WhatsApp (DDD + Número)',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'Ex: 11999999999',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o número do celular';
                        final cleaned = v.replaceAll(RegExp(r'\D'), '');
                        if (cleaned.length < 10) return 'Insira um número válido com DDD';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'E-mail do Cliente (Opcional)',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'Ex: cliente@email.com',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Valor Cobrado (R\$)',
                        prefixText: 'R\$ ',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o valor';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Descrição do Serviço ou Produto',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'Ex: Consultoria de Marketing',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Descreva o serviço/produto' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_month, color: AppTheme.primary),
                                SizedBox(width: 12),
                                Text('Vencimento', style: TextStyle(color: AppTheme.textBody)),
                              ],
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedTone,
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Tom de Mensagem',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      items: _tones.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTone = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: Colors.black),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text(
                          'GERAR MENSAGEM COM IA 🤖',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading || _generatedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROPOSTA DE COBRANÇA GERADA',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          Icon(Icons.edit_note, color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _generatedText,
                        maxLines: null,
                        key: ValueKey(_generatedText),
                        style: const TextStyle(color: AppTheme.textBody, height: 1.4),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          _generatedText = val;
                        },
                      ),
                      const Divider(height: 32, color: Colors.white10),
                      ElevatedButton.icon(
                        onPressed: _generatedText.isEmpty ? null : _sendViaWhatsApp,
                        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        label: const Text('ENVIAR NO WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generatedText.isEmpty ? null : _copyToClipboard,
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('COPIAR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textBody,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generatedText.isEmpty ? null : _sendViaEmail,
                              icon: const Icon(Icons.mail_outline_rounded, size: 16),
                              label: const Text('POR E-MAIL'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textBody,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
