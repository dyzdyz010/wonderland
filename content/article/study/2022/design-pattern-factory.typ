#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "设计模式（0）——工厂模式",
  desc: [工厂模式是一种软件设计模式，它属于创建型模式的一种。工厂模式的目的是通过抽象工厂类来创建一系列的相关或者],
  date: "2022-12-30",
  tags: (
    blog-tags.software-engineering,
    blog-tags.rust,
    blog-tags.programming,
  ),
)

工厂模式是一种软件设计模式，它属于创建型模式的一种。工厂模式的目的是通过抽象工厂类来创建一系列的相关或者依赖对象。它用于抽象化对象的创建过程。使用工厂模式能够让我们将对象的创建和使用分离开来，这样我们就可以在不修改已有代码的情况下更换新的对象。

工厂模式具有以下优点：

1. 在工厂模式中，我们可以将对象的创建过程封装在工厂类中，从而使客户端不必知道具体的实现细节。
2. 在工厂模式中，我们可以更换具体的工厂类，从而切换不同的产品。
3. 在工厂模式中，我们可以更加灵活地控制对象的创建过程，从而使得系统具有更好的扩展性。

工厂模式的缺点也是显而易见的：当需要增加新的产品时，需要修改工厂类，这违背了“开闭原则”。

下面是一个用rust实现的工厂模式的例子：

首先我们定义了一个Shape的trait和三个实现了这个trait的结构体：

```rust
trait Shape {
    fn area(&self) -> f64;
}

struct Circle {
    radius: f64,
}

impl Shape for Circle {
    fn area(&self) -> f64 {
        3.14 * self.radius * self.radius
    }
}

struct Rectangle {
    width: f64,
    height: f64,
}

impl Shape for Rectangle {
    fn area(&self) -> f64 {
        self.width * self.height
    }
}

struct Triangle {
    base: f64,
    height: f64,
}

impl Shape for Triangle {
    fn area(&self) -> f64 {
        self.base * self.height / 2.0
    }
}
```

然后我们定义一个ShapeFactory的结构体，它有一个静态方法new\_shape，用于根据给定的类型创建对应的Shape对象：

```rust
struct ShapeFactory;

impl ShapeFactory {
    fn new_shape(shape_type: &str) -> Box<dyn Shape> {
        match shape_type {
            "circle" => Box::new(Circle { radius: 1.0 }),
            "rectangle" => Box::new(Rectangle { width: 2.0, height: 3.0 }),
            "triangle" => Box::new(Triangle { base: 4.0, height: 5.0 }),
            _ => panic!("Invalid shape type"),
        }
    }
}
```

最后我们可以使用ShapeFactory来创建不同类型的Shape对象：

```rust
fn main() {
    let shape1 = ShapeFactory::new_shape("circle");
    let shape2 = ShapeFactory::new_shape("rectangle");
    
    shape1.area();
}
```
