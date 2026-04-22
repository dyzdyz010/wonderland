#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "设计模式（3）——策略模式",
  desc: [策略模式是一种常用的设计模式，它定义了一系列算法，并将每个算法封装起来，使它们可以相互替换。策略模式让算],
  date: "2022-12-31",
  tags: (
    blog-tags.software-engineering,
    blog-tags.rust,
    blog-tags.programming,
  ),
)

策略模式是一种常用的设计模式，它定义了一系列算法，并将每个算法封装起来，使它们可以相互替换。策略模式让算法独立于使用它的客户端而变化，从而使得算法可以在不影响客户端的情况下发生变化。

举个例子，假设我们有一个系统，它负责给用户发送邮件。这个系统可以使用不同的策略来发送邮件，比如通过SMTP服务器发送，或者通过API调用发送。我们可以使用策略模式来封装这些发送策略，并让系统根据需要动态地切换策略。

下面是使用Rust语言实现策略模式的例子：

```rust
struct Context<'a> {
    strategy: &'a dyn Strategy,
}

trait Strategy {
    fn execute(&self, num1: i32, num2: i32) -> i32;
}

struct AddStrategy;

impl Strategy for AddStrategy {
    fn execute(&self, num1: i32, num2: i32) -> i32 {
        num1 + num2
    }
}

struct SubtractStrategy;

impl Strategy for SubtractStrategy {
    fn execute(&self, num1: i32, num2: i32) -> i32 {
        num1 - num2
    }
}

struct MultiplyStrategy;

impl Strategy for MultiplyStrategy {
    fn execute(&self, num1: i32, num2: i32) -> i32 {
        num1 * num2
    }
}

fn main() {
    let context = Context {
        strategy: &AddStrategy,
    };
    let result = context.strategy.execute(3, 4);
    println!("Result: {}", result);

    let context = Context {
        strategy: &SubtractStrategy,
    };
    let result = context.strategy.execute(3, 4);
    println!("Result: {}", result);

    let context = Context {
        strategy: &MultiplyStrategy,
    };
    let result = context.strategy.execute(3, 4);
    println!("Result: {}", result);
}
```

在这个例子中，我们定义了一个 Context 结构体，它包含了一个策略的引用。然后我们定义了一个Strategy trait，并实现了一个 `execute` 方法用于调用策略。我们定义了三种结构体，分别实现了加、减、乘三种策略。

策略模式的优点:

1. 策略模式提供了对开放-封闭原则的完美支持，将算法封装在独立的strategy中，使得它们易于切换，易于理解，易于扩展。
2. 策略模式提供了可以替换继承的办法。策略模式是关于如何定义算法的方案，将每个算法封装到与相关的Context对象的一个独立的Strategy对象中，使得它们可以互相替换。
3. 策略模式提供了一种简单的方法来将一组特定的行为和算法封装起来，并在运行时动态地选择要使用的算法。

策略模式的缺点:

1. 策略模式会增加很多策略类，每个具体策略类都会单独存在，如果有很多策略类，势必会占用更多的系统资源。
2. 策略模式使用起来比较麻烦，会增加系统的复杂度。
