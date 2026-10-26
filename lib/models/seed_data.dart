import 'book.dart';
import 'author.dart';

const Map<int, String> genres = {
  1: 'Роман',
  2: 'Повесть',
  3: 'Рассказ',
  4: 'Пьеса',
  5: 'Поэма',
  6: 'Сатира',
  7: 'Магический реализм',
};

const Map<int, String> publishers = {
  1: 'АСТ',
  2: 'Эксмо',
  3: 'Просвещение',
  4: 'Художественная литература',
  5: 'Иностранка',
};

const List<Author> seedAuthors = [
  Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828, deathYear: 1910),
  Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821, deathYear: 1881),
  Author(id: 3, firstName: 'Антон', lastName: 'Чехов', country: 'Россия', birthYear: 1860, deathYear: 1904),
  Author(id: 4, firstName: 'Александр', lastName: 'Пушкин', country: 'Россия', birthYear: 1799, deathYear: 1837),
  Author(id: 5, firstName: 'Николай', lastName: 'Гоголь', country: 'Россия', birthYear: 1809, deathYear: 1852),
  Author(id: 6, firstName: 'Иван', lastName: 'Тургенев', country: 'Россия', birthYear: 1818, deathYear: 1883),
  Author(id: 7, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия', birthYear: 1891, deathYear: 1940),
  Author(id: 8, firstName: 'Габриэль Гарсиа', lastName: 'Маркес', country: 'Колумбия', birthYear: 1927, deathYear: 2014),
];

const List<Book> seedBooks = [
  Book(id: 1, title: 'Война и мир', isbn: '978-5-17-000001-1', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 5, copiesAvailable: 3),
  Book(id: 2, title: 'Анна Каренина', isbn: '978-5-17-000002-2', year: 1877, pages: 864, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 4, copiesAvailable: 2),
  Book(id: 3, title: 'Воскресение', isbn: '978-5-17-000003-3', year: 1899, pages: 512, publisherId: 4, authorIds: [1], genreIds: [1], copiesTotal: 3, copiesAvailable: 3),
  Book(id: 4, title: 'Преступление и наказание', isbn: '978-5-17-000004-4', year: 1866, pages: 672, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 6, copiesAvailable: 4),
  Book(id: 5, title: 'Братья Карамазовы', isbn: '978-5-17-000005-5', year: 1880, pages: 928, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 1),
  Book(id: 6, title: 'Идиот', isbn: '978-5-17-000006-6', year: 1869, pages: 640, publisherId: 4, authorIds: [2], genreIds: [1], copiesTotal: 3, copiesAvailable: 2),
  Book(id: 7, title: 'Бесы', isbn: '978-5-17-000007-7', year: 1872, pages: 736, publisherId: 5, authorIds: [2], genreIds: [1], copiesTotal: 2, copiesAvailable: 2),
  Book(id: 8, title: 'Вишнёвый сад', isbn: '978-5-17-000008-8', year: 1904, pages: 96, publisherId: 3, authorIds: [3], genreIds: [4], copiesTotal: 10, copiesAvailable: 8),
  Book(id: 9, title: 'Чайка', isbn: '978-5-17-000009-9', year: 1896, pages: 80, publisherId: 3, authorIds: [3], genreIds: [4], copiesTotal: 7, copiesAvailable: 5),
  Book(id: 10, title: 'Три сестры', isbn: '978-5-17-000010-5', year: 1901, pages: 112, publisherId: 4, authorIds: [3], genreIds: [4], copiesTotal: 5, copiesAvailable: 4),
  Book(id: 11, title: 'Евгений Онегин', isbn: '978-5-17-000011-6', year: 1833, pages: 224, publisherId: 3, authorIds: [4], genreIds: [5], copiesTotal: 8, copiesAvailable: 6),
  Book(id: 12, title: 'Капитанская дочка', isbn: '978-5-17-000012-7', year: 1836, pages: 192, publisherId: 3, authorIds: [4], genreIds: [2], copiesTotal: 6, copiesAvailable: 5),
  Book(id: 13, title: 'Мёртвые души', isbn: '978-5-17-000013-8', year: 1842, pages: 352, publisherId: 4, authorIds: [5], genreIds: [1, 6], copiesTotal: 4, copiesAvailable: 3),
  Book(id: 14, title: 'Ревизор', isbn: '978-5-17-000014-9', year: 1836, pages: 128, publisherId: 3, authorIds: [5], genreIds: [4, 6], copiesTotal: 9, copiesAvailable: 7),
  Book(id: 15, title: 'Отцы и дети', isbn: '978-5-17-000015-0', year: 1862, pages: 256, publisherId: 2, authorIds: [6], genreIds: [1], copiesTotal: 5, copiesAvailable: 4),
  Book(id: 16, title: 'Дворянское гнездо', isbn: '978-5-17-000016-1', year: 1859, pages: 320, publisherId: 4, authorIds: [6], genreIds: [1], copiesTotal: 3, copiesAvailable: 2),
  Book(id: 17, title: 'Мастер и Маргарита', isbn: '978-5-17-000017-2', year: 1967, pages: 480, publisherId: 5, authorIds: [7], genreIds: [1, 7], copiesTotal: 7, copiesAvailable: 5),
  Book(id: 18, title: 'Собачье сердце', isbn: '978-5-17-000018-3', year: 1925, pages: 128, publisherId: 2, authorIds: [7], genreIds: [2, 6], copiesTotal: 6, copiesAvailable: 4),
  Book(id: 19, title: 'Белая гвардия', isbn: '978-5-17-000019-4', year: 1925, pages: 384, publisherId: 1, authorIds: [7], genreIds: [1], copiesTotal: 4, copiesAvailable: 3),
  Book(id: 20, title: 'Сто лет одиночества', isbn: '978-5-17-000020-0', year: 1967, pages: 417, publisherId: 5, authorIds: [8], genreIds: [1, 7], copiesTotal: 5, copiesAvailable: 4),
  Book(id: 21, title: 'Любовь во время чумы', isbn: '978-5-17-000021-1', year: 1985, pages: 464, publisherId: 5, authorIds: [8], genreIds: [1, 7], copiesTotal: 3, copiesAvailable: 2),
  Book(id: 22, title: 'Осень патриарха', isbn: '978-5-17-000022-2', year: 1975, pages: 256, publisherId: 5, authorIds: [8], genreIds: [1, 7], copiesTotal: 2, copiesAvailable: 1),
];