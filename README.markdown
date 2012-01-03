# Ribbon

RuBy Object Notation

Inspired by JSON and OpenStruct.

## Quick Start

A Ribbon is a simple but powerful associative data structure designed to be easy
and natural to use. It allows the dynamic definition of arbitrary attributes,
which can easily be nested.

    r = Ribbon.new
    r.a.b.c = :d
     => {}
    r
     => {a: {b: {c: :d}}}

If a property hasn't been set, an empty Ribbon will be used as its value. This
allows you to easily and seamlessly nest any number of Ribbons. If the property
_has_ been set, its value will be returned instead.

    r.a.b.c
     => :d

You can also set the property if you give an argument to the method.

    r.a.b.c :e
     => :e
    r
     => {a: {b: {c: :e}}}

If you give it a block, the value of the option will be yielded to it.

    Ribbon.new.tap do |config|
      config.music do |music|
        music.file do |file|
          file.extensions %w(flac mp3 ogg wma)
        end
      end
    end
     => {music: {file: {extensions: ["flac", "mp3", "ogg", "wma"]}}}

If the block takes no arguments (arity of zero), it will be evaluated in the
context of the value instance. The above example could be rewritten as:

    Ribbon.new.tap do |config|
      config.music do
        file do
          extensions %w(flac mp3 ogg wma)
        end
      end
    end
     => {music: {file: {extensions: ["flac", "mp3", "ogg", "wma"]}}}

If you wish to check if a property has a value, you can simply append a `?` to
its name. If the property isn't there, `nil` will be returned and no Ribbon will
be created and stored in its place.

    r.z?
     => nil
    r
     => {}

If you append a `!` to the name of the property and give it an argument, the
value of the property will be set to it and the receiver will be returned,
allowing you to chain multiple assignments in a single line.

    r.a!(:z).s!(:x).d!(:c)
     => {a: :z, s: :x, d: :c}

You can also access the properties by key using the `[]` and `[]=` operators.
They work just like the regular method calls, which means you can chain them.

    r[:these_properties][:do_not][:exist]
    r[:they][:will_be] = :created

---

Originally part of [Acclaim](https://github.com/matheusmoreira/acclaim).
