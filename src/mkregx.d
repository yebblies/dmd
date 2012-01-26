
import std.stdio;
import std.file, std.string;

void main()
{
    auto t = readText("classnames.txt");
    
    bool[char][15] use;
    
    foreach(l; splitLines(t))
    {
        if (l.length == 0) break;
        
        foreach(i, c; l)
            use[i][c] = true;
    }
    
    foreach(i; 0..15)
        write('(');
    foreach(i; 0..15)
    {
        write('[', use[i].keys.sort, ']', ')', '?');
    }
    writeln();
}

//struct [ABCEGHILMOPST]?[ACIRYabcdehlnopsuvy]?[PRScdgjlmoprtuvx]?[AEGMTabceinprt]?[Maeknoprtu]?[Sadeflnotx]?[CDSefgnrtu]?[acelmot]?[Sacerst]?[Sent]?[Saet]?[at]?[aet]?[et]?[e]?;