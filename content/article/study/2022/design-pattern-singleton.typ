#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "设计模式（1）——单例模式",
  desc: [单例模式是一种常见的设计模式，它保证一个类只有一个实例，并提供一个全局访问点来访问这个实例。这样做的目的],
  date: "2022-12-31",
  tags: (
    blog-tags.software-engineering,
    blog-tags.rust,
    blog-tags.programming,
  ),
)

单例模式是一种常见的设计模式，它保证一个类只有一个实例，并提供一个全局访问点来访问这个实例。这样做的目的是为了限制实例的数量，并节省系统资源。

实现单例模式的方法有很多种，但常见的有以下几种：

1. 懒汉式单例：在第一次调用时才创建实例，但存在线程安全问题。
2. 饿汉式单例：在类加载时就创建实例，避免了线程安全问题，但如果实例创建失败会导致类加载失败。
3. 双重检查锁单例：使用双重检查锁的方式来保证线程安全，并且在第一次调用时才创建实例。
4. 枚举单例：使用枚举类型来实现单例，无需考虑线程安全问题。

单例模式有几个关键点：

- 一个类只有一个实例
- 该实例必须自行创建
- 必须自行向整个系统提供这个实例

下面是一个使用Rust语言实现单例模式的例子：

```rust
use std::sync::{Once, ONCE_INIT};
use std::cell::RefCell;

struct Singleton;

impl Singleton {
    fn new() -> Singleton {
        Singleton
    }
}

static mut SINGLETON: *const Singleton = 0 as *const Singleton;
static INIT: Once = ONCE_INIT;

fn get_instance() -> &'static Singleton {
    unsafe {
        INIT.call_once(|| {
            SINGLETON = Box::into_raw(Box::new(Singleton::new()));
        });
        &*SINGLETON
    }
}

fn main() {
    let instance1 = get_instance();
    let instance2 = get_instance();

    assert_eq!(instance1 as *const Singleton, instance2 as *const Singleton);
}
```

在上面的例子中，我们使用了`std::sync::Once`来保证`get_instance`函数只会被调用一次。`SINGLETON`是一个指向`Singleton`类型的指针，用于保存唯一的实例。在`get_instance`函数中，我们调用了`Once`的`call_once`方法，并传入一个闭包作为参数。当call\_once被调用的时候，传入的闭包会被执行一次。

注意，call\_once的参数闭包是不能直接调用的，而是通过Once的内部机制来调用的。这样做的好处是保证了闭包只会被调用一次，从而避免了并发的问题。

在闭包中，我们使用了Singleton的私有构造函数来创建一个新的实例。然后将这个实例的地址赋值给SINGLETON。最后，我们将SINGLETON作为函数的返回值返回。

在上面的代码中，我们使用了Once和闭包来保证get\_instance函数只会被调用一次，并且我们使用了一个全局的指针来保存唯一的实例。这样就可以保证每次调用get\_instance函数，都会返回同一个实例的地址。

使用单例模式的优点包括：

- 以保证系统中只有一个实例，避免了对象的重复创建，节省了系统资源。
- 可以方便地访问它，可以使用指定的方法来访问它，它具有一定的控制作用。

单例模式的缺点也很明显：

由于单例模式中没有抽象层，因此单例类的扩展有很大的困难；单例类的职责过重，在一定程度上违背了“单一职责原则”；由于单例模式中没有抽象层，因此无法形成基于继承的等级结构。

单例模式的使用场景：

1. 当系统中只需要一个全局对象，且该对象有着复杂的初始化过程，可以使用单例模式。
2. 当系统中需要频繁地访问一个对象，且该对象有着复杂的初始化过程，可以使用单例模式。
3. 当系统中只需要一个登录界面或者设置界面，且该界面需要访问全局数据，可以使用单例模式。
