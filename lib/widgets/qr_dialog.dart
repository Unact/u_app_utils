part of u_app_utils;

class QRDialog {
  final BuildContext _context;
  final String qr;

  QRDialog({required this.qr, required BuildContext context}) :
    _context = context;

  Future<void> open() async {
    return showDialog(
      context: _context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            color: Colors.white,
            child: bw.BarcodeWidget(
              barcode: bw.Barcode.qrCode(errorCorrectLevel: bw.BarcodeQRCorrectionLevel.quartile),
              drawText: false,
              padding: const EdgeInsets.all(8),
              data: qr,
              width: 150,
              height: 150,
            ),
          )
        );
      }
    );
  }
}
