import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/wallet/payment_details_model.dart';
import '../models/wallet/payment_method.dart';
import '../providers/wallet/save_details.dart';
import '../utils/helper/helper.dart';

class EnterDetailsPage extends ConsumerStatefulWidget {
  final String uid;
  final PaymentMethod paymentMethod;
  final PaymentDetails paymentDetails;

  const EnterDetailsPage({
    super.key,
    required this.uid,
    required this.paymentMethod,
    required this.paymentDetails,
  });

  @override
  ConsumerState<EnterDetailsPage> createState() => _EnterDetailsPageState();
}

class _EnterDetailsPageState extends ConsumerState<EnterDetailsPage> {
  late final TextEditingController _nameCon;
  late final TextEditingController _emailCon;
  late final TextEditingController _upiCon;
  late final TextEditingController _accCon;
  late final TextEditingController _ifscCon;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCon = TextEditingController(text: widget.paymentDetails.name ?? '');
    _emailCon = TextEditingController(text: widget.paymentDetails.email ?? '');
    _upiCon = TextEditingController(text: widget.paymentDetails.upiId ?? '');
    _accCon = TextEditingController(text: widget.paymentDetails.accNo ?? '');
    _ifscCon = TextEditingController(text: widget.paymentDetails.ifsc ?? '');
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _emailCon.dispose();
    _upiCon.dispose();
    _accCon.dispose();
    _ifscCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String methodId = widget.paymentMethod.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paymentMethod.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter your details for ${widget.paymentMethod.title}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Email methods
              if (methodId == PaymentMethodEnum.GOOGLE_PLAY.name ||
                  methodId == PaymentMethodEnum.GCASH.name ||
                  methodId == PaymentMethodEnum.DANA.name ||
                  methodId == PaymentMethodEnum.PAYPAL.name ||
                  methodId == PaymentMethodEnum.TOUCH_N_GO.name ||
                  methodId == PaymentMethodEnum.FLIPKART.name ||
                  methodId == PaymentMethodEnum.AMAZON.name)
                TextFormField(
                  controller: _emailCon,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'Enter your e-mail',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                ),

              // UPI method
              if (methodId == PaymentMethodEnum.UPI.name)
                TextFormField(
                  controller: _upiCon,
                  decoration: const InputDecoration(
                    labelText: 'UPI Address',
                    hintText: 'Enter your UPI address',
                  ),
                  validator: upiValidator,
                ),

              // NEFT method
              if (methodId == PaymentMethodEnum.NEFT.name) ...[
                TextFormField(
                  controller: _accCon,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account Number',
                    hintText: 'Enter your bank account number',
                  ),
                  keyboardType: TextInputType.number,
                  validator: bankAccValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ifscCon,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    hintText: 'Enter your bank IFSC code',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: ifscValidator,
                ),
              ],

              if (methodId == PaymentMethodEnum.UPI.name ||
                  methodId == PaymentMethodEnum.NEFT.name) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCon,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                  ),
                  textInputAction: TextInputAction.done,
                  validator: nameValidator,
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async => await saveDetails(
                    context,
                    _formKey,
                    widget.uid,
                    widget.paymentMethod,
                    _nameCon,
                    _emailCon,
                    _upiCon,
                    _accCon,
                    _ifscCon,
                  ),
                  child: const Text('Save Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


