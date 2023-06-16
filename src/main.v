module main

import net.http
import net.html

import strings

const c_reset = '\x1b[0m'
const c_red = '\x1b[31m'
const c_green = '\x1b[32m'
const c_yellow = '\x1b[33m'
const c_bold = '\x1b[1m'

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

fn get_max_students(tags []&html.Tag) int {
	ctxs := get_tags_content(tags)

	mut total := 0
	mut i := 0

	for n in ctxs {
		if i%2 == 0 { total += n.int() }
		i++
	}

	return total
}

fn get_total_students(tags []&html.Tag) int {
	ctxs := get_tags_content(tags)

	mut total := 0
	mut i := 0

	for n in ctxs {
		if i%2 != 0 { total += n.int() }
		i++
	}

	return total
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

fn calculate_town(id string) []int {
	resp := http.get('https://nabor.pcss.pl/'+id+'/szkolaponadpodstawowa/') or { panic(err) }
	body := html.parse(resp.body)

	all_counters := body.get_tags_by_class_name('maxstudetscount')

	max_s   := get_max_students(all_counters)
	total_s := get_total_students(all_counters)
	flood_s := total_s-max_s

	print(c_bold+capitalize_str(id)+':'+c_reset)
	if max_s != 0 {
		
		println(c_bold+'\n  Miejsca:   '+c_reset+max_s.str())
		println(c_bold+'  Uczniowie: '+c_reset+total_s.str())
		println(c_bold+'')
		if flood_s <= 0 {
			println('  Nadmiar:   '+c_reset+c_green+'Brak')
		} else {
			println('  Nadmiar:   '+c_reset+c_red+flood_s.str())
		}
		println(c_reset+'\n----------------------------\n')
		return [max_s, total_s, flood_s]
	}

	println(c_yellow+' N/A')
	println(c_reset+'\n----------------------------\n')

	return [max_s, total_s, flood_s]
}

fn main() {
	resp := http.get('https://nabor.pcss.pl/szkolaponadpodstawowa') or { panic(err) }
	body := html.parse(resp.body)

	mut max   := 0
	mut total := 0
	mut flood := 0

	tags := body.get_tags_by_class_name('instances-list')[0].get_tags('li')
	println(c_reset+'\n----------------------------\n')
	for tag in tags {
		data := calculate_town(parse_town_id(tag.get_tags('a')[0].attributes['href']))

		max   += data[0]
		total += data[1]
		flood += data[2]
	}

	println('\n')
	println(c_bold+'OGOLNIE (Wielkopolska):'+c_reset)
	println(c_bold+'  Miejsca:   '+c_reset+max.str())
	println(c_bold+'  Uczniowie: '+c_reset+total.str())
	println(c_bold+'')
	if flood <= 0 {
		println('  Nadmiar:   '+c_reset+c_green+'Brak')
	} else {
		println('  Nadmiar:   '+c_reset+c_red+flood.str())
	}
	println('\n')
}
