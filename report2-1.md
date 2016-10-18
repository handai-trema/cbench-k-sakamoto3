# 課題2-1：Cbenchの高速化
* 学籍番号：33E16009
* 氏名：坂本 昂輝

## 課題内容
Rubyのプロファイルを用いて、Cbenchのボトルネックを解析せよ。詳しくは、以下のRubyプロファイラ、もしくは他のプロファイラを用いて、CbenchやTremaのボトルネック部分を発見し、それが遅い理由を解説せよ。

### Ruby向けのプロファイラ
* [profile](https://docs.ruby-lang.org/ja/2.1.0/library/profile.html)
* [stackprof](https://github.com/tmm1/stackprof)
* [ruby-prof](https://github.com/ruby-prof/ruby-prof)

## 解答
profileはそれ自身の動作がボトルネックとなる可能性があるため利用しない。また、stackprofはdumpファイルを一定周期毎に取るため、正確なプロファイルが行えない可能性がある。したがって、今回はruby-profを用いてCbenchのボトルネックを解析した。

### 方法
まず、ruby-profを以下のコマンドでインストールし、バージョンを確認する。今回はバージョン0.16.2を用いた。

```
gem install ruby-prof
ruby-prof --version # => ruby-prof 0.16.2
```

次に、以下のコマンドでCbenchを処理するコントローラを起動する。-sオプションでどの項目でソートさせるかを決定できる。今回はself\_timeでソートしている。ソート項目に関する詳細は結果の章で記述する。-fオプションで出力先を決めることができ、profile\_result.txtの中に出力結果を返す。

```
ruby-prof -s self -f profile_result.txt ./bin/trema run ./lib/cbench.rb
```

その後、別の端末から以下のコマンドを入力し、Cbenchプロセスを動作させる。

```
./bin/cbench --port 6653 --switches 1 --loops 10 --ms-per-test 10000 --delay 1000 --throughput
```

最後に、Cbenchプロセスの後、Ctrl+CでTremaを終了させると、profile\_result.txtの中にプロファイル結果が表示される。

### 結果
結果として、profile\_result.txtの中に以下のような出力結果を得た(selfソートにおける上位の一部)。

```
Measure Mode: wall_time
Thread ID: 12622220
Fiber ID: 15567800
Total: 123.037951
Sort by: self_time

 %self      total      self      wait     child     calls  name
  0.04      0.044     0.044     0.000     0.000    19112   Symbol#to_s
  0.02      0.031     0.031     0.000     0.000    16068   Kernel#instance_variable_set
  0.02      0.304     0.026     0.000     0.278     6730  *Array#each
  0.02      0.039     0.025     0.000     0.013    12201   Kernel#initialize_dup
  0.02      0.059     0.021     0.000     0.038    12125   Kernel#dup
  0.02      0.067     0.019     0.000     0.048      436  *Module#module_eval
  0.01      0.011     0.010     0.000     0.001      150   Module#class_eval
  0.01      0.340     0.010     0.000     0.330     5898  *Class#new
  0.01      0.009     0.009     0.000     0.000     6358   Symbol#to_sym
  0.01      0.008     0.008     0.000     0.000    10700   Gem::Specification#default_value
  0.01    123.014     0.008     0.000   123.006      601  *Kernel#require
  0.01      0.007     0.007     0.000     0.000      415   String#=~
  0.01      0.007     0.007     0.000     0.000     7083   Array#initialize_copy
```

各項目の説明は以下の通りである。

* %self：全体時間の%
* total：そのメソッドの呼び出しと子メソッドの呼び出しにかかった合計時間(秒)
* self：そのメソッドの呼び出しにかかった時間(秒)
* wait：スレッドの待機時間(秒)
* child：そのメソッドの子メソッドの呼び出しにかかった時間(秒)
* calls：そのメソッドが呼び出された回数
* name：メソッド名

結果的に、メソッドの種類が多すぎて%selfでは特に差は見られなかったが、totalで見るとKernel#requireメソッドとその子メソッドの合計がボトルネックであることがわかった。また、selfソートにおける上位には現れなかったが、totalで見るとKernel#loadメソッドもボトルネックであることがわかった。

これを考慮し、./bin/cbenchの中身を見ると、以下のようにrakeやRakefileを読み込んでいることがわかる。出力結果のcallsの項を見ると、この部分を601回読み込んでおり、それぞれが新規に読み込まれているため、ボトルネックとなっていると予想する。これを改善するためには、一度読み込んだrakeやRakefileの中身をメモリに保存しておき、使い回すという案が考えられる。

```
require 'rake'
load File.expand_path(File.join(__dir__, '../Rakefile'))
```

### 本解答の問題点
本課題の解答として適切なものは、コントローラにおけるCbenchの処理で見られるボトルネックを発見することだと思っている。しかし、私が解答したものはCbenchプロセス全体のボトルネックであり、あまり適切ではないと考えている。今後、部分的なプロファイリングを適切に行う術を学び、習得でき次第もう一度本課題に向き合ってみようと思う。

## 参考文献
* [Rubyプロファイラ10選](http://blog.livedoor.jp/sonots/archives/39380434.html)
* [プロファイラーについて](http://spring-mt.hatenablog.com/entry/2013/12/21/205702)
* [ruby-profとKCacheGrind](http://blog.mirakui.com/entry/20100919/rubyprof)