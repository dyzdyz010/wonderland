#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "设计模式（2）——原型模式",
  desc: [原型模式是一种创建型设计模式，它允许你复制一个对象，而不是创建新的对象。原型模式对于创建复杂对象的场景很],
  date: "2022-12-31",
  tags: (
    blog-tags.software-engineering,
    blog-tags.rust,
    blog-tags.programming,
  ),
)

原型模式是一种创建型设计模式，它允许你复制一个对象，而不是创建新的对象。原型模式对于创建复杂对象的场景很有用，因为创建一个复杂对象的过程可能会消耗大量的时间和资源。

原型模式的基本实现方式是通过实现一个克隆自身的方法，然后调用这个方法来创建一个新的对象。这样，我们就可以通过调用克隆方法来获得一个新的对象，而不是重新创建一个新的对象。

下面是一个使用原型模式的例子，使用Rust语言实现：

```rust
use std::cell::RefCell;
use std::rc::Rc;

trait Prototype {
    fn clone(&self) -> Box<dyn Prototype>;
}

struct ConcretePrototype {
    value: i32,
}

impl Prototype for ConcretePrototype {
    fn clone(&self) -> Box<dyn Prototype> {
        Box::new(ConcretePrototype { value: self.value })
    }
}

fn main() {
    let prototype = ConcretePrototype { value: 1 };
    let prototype_clone = prototype.clone();

    println!("Original value: {}", prototype.value);
    println!("Cloned value: {}", prototype_clone.value);
}
```

在这个例子中，我们定义了一个 `Prototype` trait 和一个实现了这个 trait 的 `ConcretePrototype` 结构体。`ConcretePrototype` 结构体有一个 `value` 字段，它是一个整数。

我们在 `main` 函数中创建了一个 `ConcretePrototype` 实例，然后调用了它的 `clone` 方法，得到了一个副本。我们输出了原实例和副本的 `value` 值，可以看到它们是相同的。

原型模式的优点包括：

- 在创建新对象时无需知道创建过程，只需知道对象的类型和拷贝方法即可创建新对象，简化了对象的创建过程。
- 在运行时可以动态地改变实例的类型，通过拷贝已有对象创建新对象，可以在运行时动态地扩展系统的功能。

原型模式也有一些缺点。其中一个缺点是必须为每个类实现一个克隆方法，这可能会增加代码的复杂度；另一个缺点是如果类中存在循环引用的对象，可能会导致无限递归，从而导致系统崩溃。

总的来说，原型模式是一种灵活的创建新对象的方式，但是也有一些限制。在选择使用原型模式时，应该考虑这些限制，以决定是否使用该模式。
