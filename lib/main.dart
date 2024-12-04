import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  final TransformationController _transformationController = TransformationController();

  TextEditingController _textEditingController = TextEditingController();
  late AnimationController _animationController;

  double _imageW = 240;
  double _imageH = 320;
  double _dotSize = 6;
  Offset changeOffset = Offset.zero;

  Animation<Matrix4>? _animation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 330),
    );
    _animationController.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: Matrix4.identity(),
      end: _transformationController.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: (){
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('画面缩放测试'),
        ),
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Text('240x320'),
            Stack(
              children: [
                Container(
                  height: _imageH,
                  width: _imageW,
                  color: Colors.lightBlueAccent,
                  child: IgnorePointer(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 8.0,
                      panEnabled: false,
                      transformationController: _transformationController,
                      constrained: false,
                      child: Container(
                        width: _imageW,
                          height: _imageH,
                          color: Colors.lightBlueAccent,
                          child: Stack(
                            children: [
                              Image.asset('assets/images/img_call_screen_3.jpg'),
                              Positioned(
                                left: changeOffset.dx,
                                top: changeOffset.dy,
                                child: Container(
                                  width: _dotSize+2,
                                  height: _dotSize+2,
                                  color: Colors.lightBlueAccent,
                                ),
                              )
                            ],
                          )
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _imageW/2-_dotSize/2,
                  top: _imageH/2-_dotSize/2,
                  child: Container(
                    color: Colors.red,
                    width: _dotSize,
                    height: _dotSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('请输入放大的坐标及倍数（如30,50,2 表示x:30,y:50,scale:2倍,即将坐标（30,50）移动到中心位置，放大2倍)'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: _textEditingController,
              ),
            ),
            TextButton(onPressed: (){
              final text = _textEditingController.text;
              checkValues(text, true);

            }, child: Text('先移动选择点位')),
            TextButton(onPressed: (){
              final text = _textEditingController.text;
              checkValues(text, false);
              _resetAnimation();
            }, child: Text('开始缩放')),
            IconButton(onPressed: (){
              setState(() {
                _transformationController.value = Matrix4.identity();
                changeOffset = Offset.zero;
              });
            }, icon: Icon(Icons.refresh_outlined))
          ],
        ),
      ),
    );
  }
  checkValues(String text,bool isShowDot){
    List<String> value = text.split(',');
    if (value.length >= 3) {
      if (isShowDot) {
        doShowDot(value);
      }else{
        doTranslateAndScale(value);
      }
    }else{
      value = text.split('，');
      if (value.length >= 3) {
        if (isShowDot) {
          doShowDot(value);
        }else{
          doTranslateAndScale(value);
        }
      }else{
        value = text.split('.');
        if (value.length >= 3) {
          if (isShowDot) {
            doShowDot(value);
          }else{
            doTranslateAndScale(value);
          }
        }else{
          showMessage('输入不对，请重新输入');
        }
      }
    }
  }
  doShowDot(List<String> value){
    double x = double.tryParse(value[0]) ?? 0;
    double y = double.tryParse(value[1]) ?? 0;
    changeOffset = Offset(x-(_dotSize+2)/2, y-(_dotSize+2)/2);
    print('doShowDot -- ${changeOffset}');
    setState(() {});
  }
  doTranslateAndScale(List<String> value){
    double x = double.tryParse(value[0]) ?? 0;
    double y = double.tryParse(value[1]) ?? 0;
    double scale = double.tryParse(value[2]) ?? 0;
    changeOffset = Offset(x-(_dotSize+2)/2, y-(_dotSize+2)/2);
    print('doTranslateAndScale -- ${changeOffset}');
    Offset center = Offset(_imageW/2, _imageH/2);
    Matrix4 currentMatrix = Matrix4.identity();
    currentMatrix.translate(center.dx-x,center.dy-y);
    setState(() {
      _transformationController.value = currentMatrix;
    });

    Matrix4 nextMatrix = _transformationController.value;

    final Offset focal = Offset(x,y);
    final Matrix4 zoomMatrix = nextMatrix
      ..translate(focal.dx, focal.dy)
      ..scale(scale)
      ..translate(-focal.dx, -focal.dy);
    _transformationController.value = zoomMatrix;
  }
  showMessage(String msg){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
