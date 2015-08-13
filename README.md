# plain
D library to convert HTML into plain text.

This is useful for generating plain text alternatives from HTML emails.
It does not handle complex layouts, but it's pretty good for emails.

Uses [htmld](https://github.com/eBookingServices/htmld).

Example usage:
```d
import plain;

auto text = toplain(`
<html>
    <body>
        <table>
            <tr>
                <td>
                    <h2>Heading</h2>
                    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam sed mi at augue venenatis elementum consequat non eros. Aliquam erat volutpat. In eu diam in arcu suscipit convallis id in augue. Quisque at ipsum eu tortor faucibus rutrum at nec mi. Suspendisse luctus dui sed est vehicula pellentesque. Nullam eget tincidunt mi. Nulla suscipit leo vitae nisi porta, eu blandit augue mollis. Pellentesque ut tortor magna. Nulla ut diam in nisl aliquet dignissim sed id diam. Curabitur vitae dui scelerisque, venenatis arcu non, porta mauris. Morbi ultrices, nulla tristique varius semper, orci orci viverra eros, blandit aliquam ipsum enim ut diam. Donec convallis mollis libero nec vestibulum. <a href="www.google.com">Google</a>
                    </p>
                    <p>Interdum et malesuada fames ac ante ipsum primis in faucibus. Ut faucibus sed leo a malesuada. Pellentesque sit amet varius massa. Suspendisse laoreet dui est, facilisis viverra turpis ornare a. Proin bibendum laoreet orci, nec sollicitudin libero egestas sed. Nam ac metus vulputate nisi scelerisque ornare. In hac habitasse platea dictumst. Aenean tempus tempus leo, nec maximus quam dignissim non.
                    </p>
                    <p><img alt="girafe" src="http://www.jaunted.com/files/22421/2012_05_09_JA___BabyGiraffe.jpg" /></p>
                </td>
                <td></td>
            </tr>
            <tr>
                <td>
                    <hr/>
                    <h2>Lists</h2>
                    <ul>
                        <li>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</li>
                        <li>Vivamus sollicitudin libero quis magna lacinia, ac pulvinar nunc scelerisque.</li>
                        <li>Vivamus malesuada tortor at lectus condimentum, ut consequat nulla fermentum.</li>
                    </ul>
                    <ol>
                        <li>Praesent sit amet tellus vel elit posuere lacinia in eget dui.</li>
                        <li>Donec cursus risus sed erat venenatis tempor.</li>
						<li>Sed hendrerit nulla sed elit egestas, eget elementum elit finibus.</li>
                    </ol>
                </td>
            </tr>
            <tr>
                <td>
                    <hr/>
                    <h2>Links</h2>
					Website: <a href="http://www.google.com">http://www.google.com</a><br />
					Facebook: <a href="http://www.facebook.com/mooo">mooo</a><br />
                    E-Mail: <a href="mailto:test@example.com">E-Mail Me!</a><br />
                </td>
            </tr>
        </table>
    </body>
</html>`);

  writeln(text);
```

Output:
```
HEADING

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam sed mi at
augue venenatis elementum consequat non eros. Aliquam erat volutpat. In eu
diam in arcu suscipit convallis id in augue. Quisque at ipsum eu tortor
faucibus rutrum at nec mi. Suspendisse luctus dui sed est vehicula
pellentesque. Nullam eget tincidunt mi. Nulla suscipit leo vitae nisi porta,
eu blandit augue mollis. Pellentesque ut tortor magna. Nulla ut diam in nisl
aliquet dignissim sed id diam. Curabitur vitae dui scelerisque, venenatis arcu
non, porta mauris. Morbi ultrices, nulla tristique varius semper, orci orci
viverra eros, blandit aliquam ipsum enim ut diam. Donec convallis mollis
libero nec vestibulum. Google [www.google.com]

Interdum et malesuada fames ac ante ipsum primis in faucibus. Ut faucibus sed
leo a malesuada. Pellentesque sit amet varius massa. Suspendisse laoreet dui
est, facilisis viverra turpis ornare a. Proin bibendum laoreet orci, nec
sollicitudin libero egestas sed. Nam ac metus vulputate nisi scelerisque
ornare. In hac habitasse platea dictumst. Aenean tempus tempus leo, nec
maximus quam dignissim non.

[girafe http://www.jaunted.com/files/22421/2012_05_09_JA___BabyGiraffe.jpg]

------------------------------------------------------------------------------
LISTS
 * Lorem ipsum dolor sit amet, consectetur adipiscing elit.
 * Vivamus sollicitudin libero quis magna lacinia, ac pulvinar nunc
   scelerisque.
 * Vivamus malesuada tortor at lectus condimentum, ut consequat nulla
   fermentum.
 1. Praesent sit amet tellus vel elit posuere lacinia in eget dui.
 2. Donec cursus risus sed erat venenatis tempor.
 3. Sed hendrerit nulla sed elit egestas, eget elementum elit finibus.

------------------------------------------------------------------------------
LINKS
Website: http://www.google.com
Facebook: mooo [http://www.facebook.com/mooo]
E-Mail: E-Mail Me! [test@example.com]
```

# todo
- support for pretty printing tables
