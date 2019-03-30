import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async{
  Firestore firestore = Firestore();
  await firestore.settings(timestampsInSnapshotsEnabled: true);

  runApp(MaterialApp(home: WordBook()));
}

class WordBook extends StatefulWidget {
  @override
  _WordBookState createState() => _WordBookState();
}

class _WordBookState extends State<WordBook> {
  ScrollController _scrollController = ScrollController();
  bool _isSearch = false;
  TextEditingController _searchTxt =  TextEditingController();
  Stream _stream;
  var _ref = Firestore.instance.collection('words');

  @override
  initState(){
    super.initState();
    _stream = _ref.orderBy('title').snapshots();
  }

  Widget _buildMainList(var snapData){
    return Expanded(
      flex: 10,
      child: Scrollbar(
        child: ListView.builder(
          controller: _scrollController,
          itemCount:snapData.documents.length,
          itemBuilder: (ctx, idx) {
            return ListTile(
              title: _highlight(ctx, snapData.documents[idx]['title']),
            );
          },
        )
      )
    );
  }

  Widget _buildShortList(List _letters){
    return Expanded(
      child: ListView.builder(
        itemCount: _letters.length,
        itemBuilder: (_, idx){
          return GestureDetector(
            child: Padding(
              padding: EdgeInsets.all(1.0),
            child: CircleAvatar(
              radius: 15.0,
              child: Text(_letters[idx][0], style: Theme.of(context).primaryTextTheme.title),
              backgroundColor: Theme.of(context).primaryColor,
            )),
            onTap:()=>_scrollController
                .animateTo(_letters[idx][1], duration: Duration(milliseconds: 200), curve: Curves.ease),
          );
        }
      )
    );
  }

  Widget _buildTitle(BuildContext ctx){
    if(_isSearch){
      return TextField(
        decoration:  InputDecoration.collapsed(
          hintText: 'Search',
          hintStyle: Theme.of(ctx).primaryTextTheme.title
              .copyWith(color: Theme.of(ctx).primaryTextTheme.title.color.withOpacity(0.4)
          ),
        ),
        style: Theme.of(ctx).primaryTextTheme.title,
        onChanged: (val)=>
            setState((){
              _stream = val.length>=3 ? _ref.where('tags', arrayContains: _searchTxt.text.toUpperCase())
                  .orderBy('title').snapshots()
                  :_ref.orderBy('title').snapshots();
            }),
        controller: _searchTxt,
        autofocus: true,
      );
    }
    return Text('Contest');
  }

  Widget _buildAction() {
    if (_isSearch) {
      return IconButton(
        icon: Icon(_searchTxt.text.length>0 ? Icons.clear_all : Icons.close),
        onPressed: () =>
          setState(() {
            if (_searchTxt.text.length > 0) _searchTxt.clear();
            else _isSearch = false;

            _stream = _ref.orderBy('title').snapshots();
          })
      );
    }

    return IconButton(
      icon: Icon(Icons.search),
      onPressed: () => setState(() {_isSearch = true; })
    );
  }

  Widget _highlight(BuildContext ctx, String _title){
    if (!_isSearch || _searchTxt.text.length<3) return Text(_title);

    List<TextSpan> _chunks = List();
    int _first = _title.toUpperCase().indexOf(_searchTxt.text.toUpperCase());
    if(_first<0)
      return Text(_title);

    if(_first>0)
      _chunks.add(TextSpan(text: _title.substring(0, _first)));

    _chunks.add(TextSpan(
        text: _title.substring(_first, _first+_searchTxt.text.length),
        style: TextStyle(color: Colors.blue)
    ));
    _chunks.add(TextSpan(text: _title.substring(_first+_searchTxt.text.length)));

    return RichText(text: TextSpan(children: _chunks, style: DefaultTextStyle.of(ctx).style));
  }

  @override
  void dispose(){
    _searchTxt.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(context),
        actions: [_buildAction()],
      ),
      body: StreamBuilder(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator(),);
          if(snapshot.data.documents.length==0)
            return Center(child: Text('Nothing'));
          Map<String, dynamic> _letters = Map();
          snapshot.data.documents.forEach((document){
            String _first = document['title'].substring(0,1);
            if(!_letters.containsKey(_first))
              _letters[_first] = {
                0: _first,
                1: snapshot.data.documents.indexOf(document)*56.0
              };
            }
          );
          List _lettersList = List();
          _lettersList.addAll(_letters.values);

          return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                _buildMainList(snapshot.data),
                _buildShortList(_lettersList)
              ]
          );
        }
      ),
    );
  }
}