#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "设计模式（4）——建造者模式",
  desc: [建造者模式是一种设计模式，它可以帮助你创建复杂的对象。它通过将对象的创建过程封装在一个专门的建造者对象中],
  date: "2022-12-31",
  tags: (
    blog-tags.software-engineering,
    blog-tags.rust,
    blog-tags.programming,
  ),
)

建造者模式是一种设计模式，它可以帮助你创建复杂的对象。它通过将对象的创建过程封装在一个专门的建造者对象中，来帮助你创建复杂的对象。

建造者模式由以下四个部分组成：

- 产品（Product）：表示要创建的复杂对象。
- 抽象建造者（Builder）：定义了如何创建产品的接口。
- 具体建造者（ConcreteBuilder）：实现了抽象建造者的接口，并负责创建产品的具体实现。
- 指挥者（Director）：调用建造者的方法来创建产品。

建造者模式的优点包括：

- 将复杂对象的创建过程封装在建造者对象中，使得创建过程更加清晰。
- 可以使用不同的具体建造者来创建不同的产品。
- 可以使用指挥者类来控制产品的创建过程，使得创建过程更加灵活。
- 可以在不暴露产品内部细节的情况下，指导产品的创建过程。

建造者模式的缺点包括：

- 建造者模式需要较多的代码来实现，可能会导致代码量较大。
- 如果产品的内部变化复杂，则可能需要定义较多的具体建造者类来实现这些变化，这会使得系统变得复杂。
- 由于建造者模式中的抽象建造者类需要定义创建所有部件的方法，因此如果产品的内部变化很少，则建造者模式可能会带来很多冗余的代码。

下面是使用 rust 语言实现建造者模式的一个简单例子：

```rust
struct Product {
    field1: i32,
    field2: String,
    field3: bool,
}

trait Builder {
    fn set_field1(&mut self, value: i32);
    fn set_field2(&mut self, value: String);
    fn set_field3(&mut self, value: bool);
    fn build(self) -> Product;
}

struct ConcreteBuilder {
    field1: i32,
    field2: String,
    field3: bool,
}

impl Builder for ConcreteBuilder {
    fn set_field1(&mut self, value: i32) {
        self.field1 = value;
    }

    fn set_field2(&mut self, value: String) {
        self.field2 = value;
    }

    fn set_field3(&mut self, value: bool) {
        self.field3 = value;
    }

    fn build(self) -> Product {
        Product {
            field1: self.field1,
            field2: self.field2,
            field3: self.field3,
        }
    }
}

struct Director {
    builder: Box<dyn Builder>,
}

impl Director {
    fn set_builder(&mut self, builder: Box<dyn Builder>) {
        self.builder = builder;
    }

    fn build_product(&mut self) -> Product {
        self.builder.set_field1(1);
        self.builder.set_field2("hello".to_string());
        self.builder.set_field3(true);
        self.builder.build()
    }
}

fn main() {
    let mut director = Director {
        builder: Box::new(ConcreteBuilder {
            field1: 0,
            field2: "".to_string(),
            field3: false,
        }),
    };
    let product = director.build_product();
    println!("field1: {}, field2: {}, field3: {}", product.field1, product.field2, product.field3);
}
```

在这个例子中，我们定义了一个 `Product` 结构体，表示要创建的复杂对象。我们还定义了一个 `Builder` trait，它定义了如何创建产品的接口。然后，我们定义了一个 `ConcreteBuilder` 结构体，它实现了 `Builder` trait，并负责创建产品的具体实现。最后，我们定义了一个 `Director` 结构体，它调用建造者的方法来创建产品。

在 `main` 函数中，我们创建了一个 `Director` 对象，并将一个 `ConcreteBuilder` 对象设置为建造者。然后，我们调用 `build_product` 方法来创建产品，并打印产品的字段。
