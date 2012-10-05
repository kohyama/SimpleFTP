# SimpleFTP

An ActionScript3 class to put string to and get as string from files on FTP servers

# Preparation

Put SimpleFTP.as in the same directory as your AS3 file.
And `import SimpleFTP;` in your AS3 action.

You may need to change `publish settings` of your swf.
Select `publish settings` of `FILE` menu, select `Flash(.swf)`,
open `ADVANCED` and set `local security` to `access only network`.
To execute in another FlashPlayer, you may need to add your swf file
to the trusted list of `global security settings` of your FlashPlayer.
If you already loaded your swf, you may need to clear cache and reload your swf
after changing `global serurity settings`.

With Japanese version, 
`ファイル` メニューの `パブリッシュ設定` で `Flash(.swf)` を選び,
`詳細` を開いて `ローカルでの再生に関するセキュリティ` を
`ネットワークにのみアクセスする` に設定します.
他の FlashPlayer で実行するには, その FlashPlayer の
`グローバルセキュリティ設定` の `信頼されている場所設定` で,
実行しようとしている swf ファイルのパスを追加する必要があります.
もし, 既に swf をロード済みなら, `グローバルセキュリティ設定` を変更
した後に, FlashPlayer のキャッシュを削除し, swf を再ロードする必要が
あるかもしれません.

# To get a file

To get contents of a file on a FTP server as an UTF string, do

    SimpleFTP.get(host, user, pass, path, handler);

where

* `host`: hostname or IP address of FTP server
* `user`: username of one of accounts of your FTP server or "anonymous"
* `pass`: password of `user` or a mail address for "anonymous"
* `path`: an absolute or a relative path to the default directory of FTP server
* `handler`: a function to receive response of a FTP session.
Its type should be `function (res:String, contents:String):void`.

To check if your session succeeded or not, check if `res.substr(0,3) == "226"`,
otherwise `SimpleFTP.get()` calls your `handler` with `res` the response from
FTP server which is not equal to the expected.
If `res.substr(0,3) == "226"`, `contents` is the contents of
the file you specified.

# To put a file

To put an UTF string to a file on a FTP server, do

    SimpleFTP.put(host, user, pass, path, contents, handler);

where

* `host`: hostname or IP address of FTP server
* `user`: username of one of accounts of your FTP server or "anonymous"
* `pass`: password of `user` or a mail address for "anonymous"
* `path`: an absolute or a relative path to the default directory of FTP server
* `contents`: an UTF string you want to put
* `handler`: a function to receive response of a FTP session.
Its type should be `function (res:String):void`.

To check if your session succeeded or not, check if `res.substr(0,3) == "226"`,
otherwise `SimpleFTP.get()` calls your `handler` with `res` the response from
FTP server which is not equal to the expected.
If `res.substr(0,3) == "226"`, `contents` should saved as the file you specified.

# Assumed Getting Steps

```
220 Service ready for new user.
USER anonymous
331 Anonymous access allowed, send identity (e-mail name) as password.
PASS ftp@ftp
230 User logged in, proceed.
TYPE I
200 Command okay.
PASV
227 Entering Passive Mode (192,168,27,94,15,215).
(connect to ip1.ip2.ip3.ip4:port1*256+port2 with another socket. call it the data socket)
RETR puttest.txt
125 Data connection already open; transfer starting.
(or 550 File unavailable (e.g., file not found, no access).)
(FTP server writes contents of file to the data socket)
(FTP server close the data socket)
226 Closing data connection. 
QUIT
221 Service closing control connection.
```

# Assumed Putting Steps

```
220 Service ready for new user.
USER anonymous
331 Anonymous access allowed, send identity (e-mail name) as password.
PASS ftp@ftp
230 User logged in, proceed.
TYPE I
200 Command okay.
DELE puttest.txt
550 File unavailable (e.g., file not found, no access).
(or 250 if the file already exists)
PASV
227 Entering Passive Mode (ip1,ip2,ip3,ip4,port1,port2).
STOR puttest.txt
(connect to ip1.ip2.ip3.ip4:port1*256+port2 with another socket. call it the data socket)
125 Data connection already open; transfer starting.
(write bytes of contents to the data socket)
(close the data socket)
226 Closing data connection. 
QUIT
221 Service closing control connection.
```

# Example

Here is an example. 
Assuming you have

* host1TB as fl.controls.TextBox
* path1TB as fl.controls.TextBox
* contents1TA as fl.controls.TextArea
* host2TB as fl.controls.TextBox
* path2TB as fl.controls.TextBox
* contents2TA as fl.controls.TextArea
* host3TB as fl.controls.TextBox
* path3TB as fl.controls.TextBox
* contents3TA as fl.controls.TextArea
* getB as fl.controls.Button
* putB as fl.controls.Button
* logTA as fl.controls.TextArea

with each purpose is implied by its name.

```ActionScript
import flash.events.Event;
import flash.events.MouseEvent;
import fl.controls.Button;
import SimpleFTP;

getB.addEventListener(MouseEvent.CLICK, getHandler);
putB.addEventListener(MouseEvent.CLICK, putHandler);

function getHandler(event:MouseEvent):void
{
  logTA.text = "";
  contents1TA.text = "";
  contents2TA.text = "";
  contents3TA.text = "";

  SimpleFTP.getFile(
    host1TB.text, // host
    "anonymous",  // user
    "ftp@ftp",    // pass
    path1TB.text, // path
    // handler
    function (res:String, contents:String):void {
      logTA.appendText(res);
      if (res.substr(0, 3) == "226")
        contents1TA.appendText(contents);
    });

  SimpleFTP.getFile(host2TB.text, "anonymous", "ftp@ftp", path2TB.text,
            function (res:String, contents:String):void {
              logTA.appendText(res);
              if (res.substr(0, 3) == "226")
                  contents2TA.appendText(contents);});
  SimpleFTP.getFile(host3TB.text, "anonymous", "ftp@ftp", path3TB.text,
            function (res:String, contents:String):void {
              logTA.appendText(res);
              if (res.substr(0, 3) == "226")
                  contents3TA.appendText(contents);});
}

function putHandler(event:MouseEvent):void
{
  logTA.text = "";
  SimpleFTP.putFile(
    host1TB.text, // host
    "anonymous",  // user
    "ftp@ftp",    // pass
    path1TB.text, // path
    contents1TA.text, // contents
    function (res:String):void {logTA.appendText(res);} // handler
    );
  SimpleFTP.putFile(host2TB.text, "anonymous", "ftp@ftp", path2TB.text, contents2TA.text,
    function (res:String):void {logTA.appendText(res);});
  SimpleFTP.putFile(host3TB.text, "anonymous", "ftp@ftp", path3TB.text, contents3TA.text,
    function (res:String):void {logTA.appendText(res);});
}
```
