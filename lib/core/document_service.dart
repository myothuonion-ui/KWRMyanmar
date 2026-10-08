import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

class DocumentService {
  Future<String> imageText(Uint8List bytes,String extension) async {
    final directory=await getTemporaryDirectory();
    final file=File('${directory.path}/kwr_ocr_${DateTime.now().microsecondsSinceEpoch}.$extension');
    final recognizer=TextRecognizer(script:TextRecognitionScript.korean);
    try {
      await file.writeAsBytes(bytes,flush:true);
      return (await recognizer.processImage(InputImage.fromFilePath(file.path))).text;
    } finally {
      await recognizer.close();
      if(await file.exists()) await file.delete();
    }
  }
  Future<String> extract(Uint8List bytes,String extension,void Function(String) progress) async {
    if(extension!='pdf') return '[Image · Korean/Latin OCR]\n${await imageText(bytes,extension)}';
    await pdfrxFlutterInitialize();
    final document=await PdfDocument.openData(bytes,sourceName:'import-${DateTime.now().microsecondsSinceEpoch}');
    try {
      if(document.pages.length>40) throw const FormatException('ဖိုင်တစ်ခုလျှင် စာမျက်နှာ ၄၀အထိ ထည့်ပါ။ ဖိုင်ခွဲပြီး ပြန်ထည့်နိုင်ပါတယ်။');
      final text=StringBuffer();
      for(final page in document.pages) {
        progress('စာမျက်နှာ ${page.pageNumber} / ${document.pages.length}');
        var pageText=(await page.loadStructuredText()).fullText;
        var method='PDF text';
        if(pageText.trim().length<12) {
          method='Korean/Latin OCR';
          final scale=(1800/page.width).clamp(1.0,2.0);
          final rendered=await page.render(fullWidth:page.width*scale,fullHeight:page.height*scale);
          if(rendered!=null) {
            try {
              final image=await rendered.createImage();
              try {
                final png=await image.toByteData(format:ui.ImageByteFormat.png);
                if(png!=null) pageText=await imageText(png.buffer.asUint8List(),'png');
              } finally {image.dispose();}
            } finally {rendered.dispose();}
          }
        }
        text.writeln('[Page ${page.pageNumber} · $method]\n$pageText\n');
        if(text.length>180000) {text.writeln('[စာသားရှည်လွန်း၍ ကျန်စာမျက်နှာကို မထုတ်ယူရသေးပါ။]');break;}
      }
      return text.toString();
    } finally {document.dispose();}
  }
}
