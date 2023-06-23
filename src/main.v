module main

import net.http
import net.html

import strings

const (
    c_reset = '\x1b[0m'
    c_red = '\x1b[31m'
    c_green = '\x1b[32m'
    c_yellow = '\x1b[33m'
    c_bold = '\x1b[1m'

	c_len = 5
)

const global_padding = 2

fn strip_end(str string) string {
	s := str.reverse()
	mut us := []u8{}

	for ch in s {
		if ch != 32 {
			us << ch
		}
	}

	mut b := strings.new_builder(0)
	b.write(us) or { panic(err) }
	return b.str().reverse()
}

fn get_tags_content(tags []&html.Tag) []string {
	mut ctxs := []string{}
	for tag in tags { ctxs << strip_end(tag.content) }
	return ctxs
}

fn get_students_count(tags []&html.Tag, even bool) int {
    ctxs := get_tags_content(tags)

    mut total := 0
    mut i := 0

    for n in ctxs {
        if (even && i%2 == 0) || (!even && i%2 != 0) {
            total += n.int()
        }
        i++
    }

    return total
}

fn get_max_students(tags []&html.Tag) int {
    return get_students_count(tags, true)
}

fn get_total_students(tags []&html.Tag) int {
    return get_students_count(tags, false)
}

fn capitalize_str(str string) string {
	return str[0..1].to_upper()+str[1..]
}

fn parse_town_id(str string) string {
	s := str
	parts := s.split('/')
    extracted_string := parts[1]
	return extracted_string
}

fn print_padding(first_len int, second_len int, text string, additional int) {
	for _ in 0..(first_len - second_len - text.len - (global_padding+1) + additional) {
		print(' ')
	}
	println(text)
}

fn calculate_town(id string) []int {
	resp := http.get('https://nabor.pcss.pl/'+id+'/szkolaponadpodstawowa/') or { panic(err) }
	body := html.parse(resp.body)

	all_counters := body.get_tags_by_class_name('maxstudetscount')

	max_s   := get_max_students(all_counters)
	total_s := get_total_students(all_counters)
	flood_s := total_s-max_s

	town_name := capitalize_str(id)

	spacer := '\n----------------------------\n'

	print(c_bold+town_name+':'+c_reset+c_yellow)
	if max_s != 0 {
		print(c_reset+c_bold+'\n  Miejsca:   '+c_reset) /////
		if max_s == 0 {
			print_padding(spacer.len, '  Miejsca:   '.len, c_yellow+'N/A', c_len)
		} else {
			print_padding(spacer.len, '  Miejsca:   '.len, max_s.str(), 0)
		}

		print(c_reset+c_bold+'  Uczniowie: '+c_reset)   /////
		if total_s == 0 {
			print_padding(spacer.len, '  Uczniowie: '.len, c_yellow+'N/A', c_len)
		} else {
			print_padding(spacer.len, '  Uczniowie: '.len, total_s.str(), 0)
		}

		print(c_reset+c_bold+'  Nadmiar:   '+c_reset) /////
		if flood_s <= 0 && (total_s != 0 && max_s != 0){
			print_padding(spacer.len, '  Nadmiar:   '.len, c_green+'Brak', c_len)
		} else if total_s == 0 || max_s == 0 {
			print_padding(spacer.len, '  Nadmiar:   '.len, c_yellow+'N/A', c_len)
		} else {
			print_padding(spacer.len, '  Nadmiar:   '.len, c_red+flood_s.str(), c_len)
		}

		println(c_reset+spacer)
		return [max_s, total_s, flood_s]
	}

	print_padding(spacer.len, town_name.len+1, 'N/A', 0)
	println(c_reset+spacer)

	return [max_s, total_s, flood_s]
}

fn main() {
	resp := http.get('https://nabor.pcss.pl/szkolaponadpodstawowa') or { panic(err) }
	body := html.parse(resp.body)

	mut max   := 0
	mut total := 0
	mut flood := 0

	tags := body.get_tags_by_class_name('instances-list')[0].get_tags('li')

	spacer := '\n----------------------------\n'

	println(c_reset+spacer)

	for tag in tags {
		data := calculate_town(parse_town_id(tag.get_tags('a')[0].attributes['href']))

		max   += data[0]
		total += data[1]
		flood += data[2]
	}

	println('')
	println(c_bold+'OGOLNIE (Wielkopolska):'+c_reset)
	print(c_bold+'  Miejsca:   '+c_reset) print_padding(spacer.len, '  Miejsca:   '.len, max.str(), 0)
	print(c_bold+'  Uczniowie: '+c_reset) print_padding(spacer.len, '  Uczniowie: '.len, total.str(), 0)
	println(c_bold+'')

	if flood <= 0 {
		print('  Nadmiar:   '+c_reset+c_green) print_padding(spacer.len, '  Nadmiar:   '.len, 'Brak', 0)
	} else {
		print('  Nadmiar:   '+c_reset+c_red) print_padding(spacer.len, '  Nadmiar:   '.len, flood.str(), 0)
	}

	println('\n')
}
