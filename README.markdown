# Ribbon

RuBy Object Notation

Inspired by JSON and OpenStruct.

## Quick Start

A Ribbon is a simple but powerful associative data structure designed to be easy
and natural to use. It allows the dynamic definition of arbitrary attributes,
which can easily be nested.

    > r = Ribbon.new
    > r.a.b.c = :d
     => {}
    > r
     => {a: {b: {c: :d}}}

If a property hasn't been set, an empty Ribbon will be used as its value. This
allows you to easily and seamlessly nest any number of Ribbons. If the property
_has_ been set, its value will be returned instead.

    > r.a.b.c
     => :d

You can also set the property if you give an argument to the method.

    > r.a.b.c :e
     => :e
    > r
     => {a: {b: {c: :e}}}

If you give it a block, the value of the option will be yielded to it.

    > Ribbon.new.tap do |config|
        config.music do |music|
          music.file do |file|
            file.extensions %w(flac mp3 ogg wma)
          end
        end
      end
     => {music: {file: {extensions: ["flac", "mp3", "ogg", "wma"]}}}

If the block takes no arguments (arity of zero), it will be evaluated in the
context of the value instance. The above example could be rewritten as:

    > Ribbon.new.tap do |config|
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

    > r.z?
     => nil
    > r
     => {}

If you append a `!` to the name of the property and give it an argument, the
value of the property will be set to it and the receiver will be returned,
allowing you to chain multiple assignments in a single line.

    > r.a!(:z).s!(:x).d!(:c)
     => {a: :z, s: :x, d: :c}

You can also access the properties by key using the `[]` and `[]=` operators.
They work just like the regular method calls, which means you can chain them.

    > r[:these_properties][:do_not][:exist]
    > r[:they][:will_be] = :created

### Ribbon Wrappers

Since Ribbons inherit from BasicObject, they don't include many general-purpose
methods. In order to solve that problem, `Ribbon::Wrapper` is provided. With a
wrapped Ribbon instance, you can treat it as if it were an ordinary hash.

    > w = Ribbon::Wrapper.new
    > w[:x]
     => nil
    > w.fetch :x, 10
     => 10

All undefined methods will be forwarded to the Ribbon's internal hash. However,
if the hash doesn't respond to the method, it will be forwarded to the Ribbon
itself. In other words, you can use wrapped ribbons as if they weren't wrapped,
too.

    > w.x?
     => nil
    > w.x.y.z = 10
     => 10

One big difference to be aware of is that dynamic property creation and access
via square brackets isn't available with wrapped ribbons, because hashes respond
to `[]`.

    > w[:undefined][:property]
     => NoMethodError: undefined method `[]' for nil:NilClass

Also noteworthy is the fact that wrapping a ribbon will not modify it; nested
ribbons will not be wrapped. However, the are the methods `wrap_all!` and
`unwrap_all!`, which will recursively wrap and unwrap every ribbon,
respectively, are available.

In addition to that, many other useful methods are implemented, such as
`to_hash`, which recursively converts the ribbon and all nested ribbons to pure
hashes, and `to_yaml`, which serializes the ribbon in YAML format.

Finally, you may access the wrapped ribbon's internal hash using the `hash`
attribute, and access the wrapped ribbon itself using the `ribbon` attribute.

---

Originally part of [Acclaim](https://github.com/matheusmoreira/acclaim).
