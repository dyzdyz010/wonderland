#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "向UE5项目中集成Protobuf",
  desc: [向UE5项目中集成Protobuf],
  date: "2022-10-12",
  tags: (
    blog-tags.ue5,
    blog-tags.programming,
    blog-tags.protobuf,
  ),
)

*虚幻引擎版本：5.0.3*

*Protobuf版本：21.7*

#quote(block: true)[
  作为不懂C++的人，向UE集成C++库真的是一种折磨。
  
  ——沃兹基·硕德
]