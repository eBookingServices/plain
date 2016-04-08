module plain.plain;


import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.range;
import std.regex;
import std.string;
import std.uni;
import std.utf;


import html.dom;


private __gshared auto wordSplitter = ctRegex!(`\s|\n|\t|\r`);


private size_t tagHashOf(const(char)[] x) {
	size_t hash = 5381;
	foreach(i; 0..x.length)
		hash = (hash * 33) ^ cast(size_t)(std.ascii.toLower(x.ptr[i]));
	return hash;
}


private bool isAbsoluteHRef(const(char)[] href) {
	return (!href.empty && ((href.front == '/') || (href.indexOf("://") >= 0)));
}


struct Options {
	uint wrap = 78;			// wrap column
	uint indent;			// global indent
	dchar listMarker = '*'; // list item decorator
	string baseHRef;		// base URL for local hrefs
	string[] skipElements;	// CSS selector of elements to skip
	bool solidLinks = true;	// keep links in a single line
}


private struct TraverseState {
	uint heading;				// inside <h?></h?>
	uint pre;					// inside <pre></pre>
	uint indent;				// current indent for new lines
	uint wrap;					// current wrapping column
	uint line;					// current line length
	uint index;					// list item index
	uint indexWidth;			// list item index width
	bool skipOneIndent;			// skip indent on the first line

	Selector[] skipElements;

	Options options;
}


private auto textFormat(Appender)(ref Appender app, HTMLString text, ref TraverseState state, bool link = false) {
	size_t lines = 1;
	size_t words = 0;
	size_t length = state.line;

	foreach(word; text.splitter(wordSplitter)) {
		if (word.empty)
			continue;

		if ((words == 0) && !state.line) {
			if (!state.skipOneIndent) {
				app.put(' '.repeat(state.indent));
			} else {
				state.skipOneIndent = false;
			}
		}
		++words;

		size_t wordLength = 0;
		foreach(d; word.byDchar)
			++wordLength;

		auto extra = ((length != 0) && (length != state.wrap)) ? 1 : 0;
		if (!state.wrap || (length + extra + wordLength <= state.wrap)) {
			if (extra) {
				app.put(' ');
				++length;
			}

			app.put(word);
			length += wordLength;
		} else {
			while (wordLength) {
				app.put('\n');
				app.put(' '.repeat(state.indent));

				if ((link && state.options.solidLinks) || (wordLength <= state.wrap)) {
					app.put(word);
					length = wordLength;
					wordLength = 0;
				} else {
					auto indexSplit = word.toUCSindex(state.wrap);
					app.put(word[0..indexSplit]);
					word = word[indexSplit..$];
					length = state.wrap;
					wordLength -= state.wrap;
				}
				++lines;
			}
		}
	}

	state.line = cast(uint)length;
}


private void traverse(Appender)(ref Appender app, Node* node, ref TraverseState state) {
	final switch (node.type) with (NodeTypes) {
	case Element:
		foreach(selector; state.skipElements) {
			if (selector.matches(node))
				return;
		}

		auto hash = tagHashOf(node.tag);

		switch (hash) {
		case tagHashOf("a"):
			auto start = app.data.length;
			foreach(child; node.children)
				traverse(app, child, state);
			auto label = cast(string)app.data[start..$].strip;

			if (label.empty && node.hasAttr("title"))
				label = cast(string)node.attr("title").strip;

			auto href = node.hasAttr("href") ? node.attr("href").strip : null;
			if (href == label)
				href = null;

			if ((href.length >= 7) && (href[0..7] == "mailto:")) {
				href = href[7..$];
				if (href == label)
					href = null;
			} else if (!href.empty && (href.front == '#')) {
				href = null;
			}

			auto absolute = href.isAbsoluteHRef;

			if (!href.empty) {
				auto space = (!app.data.empty && (app.data.back != '\n')) ? " " : "";
				textFormat(app, format("%s[%s%s]", space, (absolute ? "" : state.options.baseHRef), href), state, true);
			}
			break;

		case tagHashOf("br"):
			app.put('\n');
			state.line = 0;
			break;

		case tagHashOf("img"):
			auto label = node.hasAttr("alt") ? node.attr("alt").strip : "image";
			auto src = node.hasAttr("src") ? node.attr("src").strip : null;
			auto hasSrc = !src.empty && (((src.length < 4) || (src[0..4] != "cid:")) && ((src.length < 5) || (src[0..5] != "data:")));

			if (hasSrc) {
				auto absolute = src.isAbsoluteHRef;
				textFormat(app, format("[%s %s%s]", label, (absolute ? "" : state.options.baseHRef), src), state, true);
			} else if (!label.empty)  {
				textFormat(app, format("[%s]", label), state);
			}
			break;

		case tagHashOf("h1"):
		case tagHashOf("h2"):
		case tagHashOf("h3"):
		case tagHashOf("h4"):
		case tagHashOf("h5"):
		case tagHashOf("h6"):
			++state.heading;
			foreach(child; node.children)
				traverse(app, child, state);
			--state.heading;
			app.put('\n');
			state.line = 0;
			break;

		case tagHashOf("hr"):
			app.put('\n');
			state.line = 0;
			app.put(' '.repeat(state.indent));
			app.put('-'.repeat(state.wrap));
			app.put('\n');
			state.line = 0;
			break;

		case tagHashOf("li"):
			auto liState = state;
			liState.index = 0;
			liState.indexWidth = 0;
			liState.indent = state.indent + state.indexWidth + 3;
			liState.skipOneIndent = true;
			liState.wrap = state.wrap ? state.wrap - (state.indexWidth + 3) : 0;

			if (!state.skipOneIndent)
				app.put(' '.repeat(state.indent));

			if (state.index) {
				auto start = app.data.length;
				formattedWrite(app, " %s. ", state.index);
				auto len = app.data.length - start - 3;
				app.put(' '.repeat(state.indexWidth - len));
				++state.index;
			} else {
				formattedWrite(app, " %s ", state.options.listMarker);
			}

			foreach(child; node.children)
				traverse(app, child, liState);
			app.put('\n');
			break;

		case tagHashOf("ol"):
			enum itemHash = tagHashOf("li");

			auto itemCount = 0;
			foreach(child; node.children) {
				if (child.type != NodeTypes.Element)
					continue;

				if (tagHashOf(child.tag) == itemHash)
					++itemCount;
			}

			if (itemCount) {
				auto olState = state;
				olState.index = 1;
				olState.indexWidth = cast(uint)(itemCount.to!string.length);

				foreach(child; node.children)
					traverse(app, child, olState);
			}
			break;

		case tagHashOf("p"):
			app.put('\n');
			state.line = 0;
			foreach(child; node.children)
				traverse(app, child, state);
			app.put('\n');
			state.line = 0;
			break;

		case tagHashOf("pre"):
			app.put('\n');
			state.line = 0;
			++state.pre;
			foreach(child; node.children)
				traverse(app, child, state);
			app.put('\n');
			--state.pre;
			state.line = 0;
			break;

		case tagHashOf("head"):
		case tagHashOf("script"):
		case tagHashOf("style"):
		case tagHashOf("title"):
			break;

		default:
			foreach(child; node.children)
				traverse(app, child, state);
			break;
		}
		break;

	case Text:
		if (!state.pre) {
			textFormat(app, state.heading ? node.text.toUpper : node.text, state);
		} else {
			app.put(node.text);
		}
		break;

	case Comment:
	case CDATA:
	case Declaration:
	case ProcessingInstruction:
		break;
	}
}


void toplain(Appender)(ref Appender app, Node* root, Options options = Options()) {
	TraverseState state;
	state.options = options;
	state.wrap = options.wrap;
	state.indent = options.indent;

	state.skipElements.reserve(options.skipElements.length);
	foreach(selector; options.skipElements) {
		state.skipElements ~= Selector.parse(selector);
	}

	traverse(app, root, state);
}


string toplain(Node* root, Options options = Options()) {
	auto app = appender!string;
	toplain(app, root, options);
	return app.data;
}


string toplain(Document doc, Options options = Options()) {
	auto app = appender!string;
	toplain(app, doc.root, options);
	return app.data;
}


string toplain(string html, Options options = Options()) {
	auto doc = createDocument(html);
	return toplain(doc, options);
}
