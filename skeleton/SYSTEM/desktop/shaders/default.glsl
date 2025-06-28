#if defined(VERTEX)
attribute vec2 VertexCoord;
attribute vec2 TexCoord;
varying vec2 vTexCoord;

void main() {
    // Flip Y-axis in the vertex shader
    vTexCoord = vec2(TexCoord.x, 1.0 - TexCoord.y);  // Flip Y
    gl_Position = vec4(VertexCoord, 0.0, 1.0);
}
#endif

#if defined(FRAGMENT)
uniform sampler2D Texture;
varying vec2 vTexCoord;

void main() {
    gl_FragColor = texture2D(Texture, vTexCoord);
}
#endif