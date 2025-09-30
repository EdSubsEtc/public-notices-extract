// used to convert common caode pages

import iconvLite from 'iconv-lite';

// const fs = require('fs');

export function rtfToText(rtf: string): string {

    let text = rtf;

    let headerInfo = /^\{\\(rtf(\d?))\\(ansi|mac|pc|pca)?\\(ansicpg(\d*?)\\)?/.exec(text);


    let validRTF = true;
    let encoding = 'ansi';
    let codePage = '1252';


    if (headerInfo) {

        if (headerInfo[2]) {
            //console.log("Standard RTF 1x");
        } else {
            //console.log("none standard RTF - no rtf1 keyword");
            validRTF = false;
        }

        if (headerInfo[3]) {
            //console.log("Character Encoding:" + headerInfo[3]);
            encoding = headerInfo[3];
        }

        if (headerInfo[5]) {
            //console.log("Code Page Specified:" + headerInfo[5]);
            codePage = headerInfo[5];
        } else {
            //console.log("Assuming Code Page 1252");
        }


    }

    // rtf files are 7bit encoded ansi...
    // \'xx where xx is hexadecimal is used to exteded char set encoding
    const findExtAnsi: RegExp = /\\'([a-f0-9]{2})/gs;


    let rxRes: RegExpExecArray | null;
    let rep: string;

    while (rxRes = findExtAnsi.exec(text)) {

        const extendedAnsi: string = rxRes[0];

        if (extendedAnsi) {
            rep = iconvLite.decode(Buffer.from([parseInt(extendedAnsi, 16)]), codePage);
            text = text.substr(0, rxRes.index) + rep + text.substr(rxRes.index + rxRes[0].length);
            findExtAnsi.lastIndex = 0;
        }

    };

    // \uxxxxS where xxxx is hexadecimal,  is used for unicode, and S is the 7 bit substitution
    const findFdUpUnicode = /\\u(\d{3,5})./gs;
    while (rxRes = findFdUpUnicode.exec(text)) {

        const encodedUnicode: string | undefined = rxRes[1];

        if (!encodedUnicode) {
            continue;
        }

        const unicodeValue = Number.parseInt(encodedUnicode);
        text = text.substr(0, rxRes.index) + String.fromCharCode(unicodeValue) + text.substr(rxRes.index + rxRes[0].length);
        findFdUpUnicode.lastIndex = 0;
    };

    if (rtf == null || rtf == undefined) {
        debugger;
    }

    if (rtf.match("f1 Verdana")) {

        // remove header
        text = text.replace(/\{.*?\\ulnone /, '');

        // remove tail
        text = text.replace(/\}.*$/gs, '');

        // remove par formats
        text = text.replace(/\[.*?\]/gs, '');

        // risky early finish!

        return text;

    };






    // lf + cr are for humans!
    text = text.replace(/\r?\n/gs, '');

    // remove the final } and whitespace
    text = text.replace(/[\s}]*$/gs, '');

    // remove miles break point ( and other invisibles)
    // without consulting the actual builder we cant tell if the B is a line break or not.
    text = text.replace(/\\v\s.*?\\v0\s?/gs, '\n');
    // alternative form
    text = text.replace(/\{\\v.*?\}/gs, '\n');

    // remove all the header and defs + white space if any
    //text = text.replace(/^\{\\rtf.*?(\{\\.*tbl.*?\})?\s*\}\s*/gs, '');
    text = text.replace(/\{\\.*\}/gs, '');

    // soft line return
    text = text.replace(/\\line\s?/gs, '\n');

    // hard line return
    text = text.replace(/\\pard\s?/gs, '');
    text = text.replace(/\\par\s?/gs, '\n');

    //apos
    text = text.replace(/\\rquote\s?/gs, '\u2019');

    // remove all other tags that we dont care about
    // this version was removing some new lines...
    //text = text.replace(/\\.*?\s/gs, '');

    text = text.replace(/\\\w* ?/gs, '');

    // remove any leading whitespace
    text = text.replace(/^\s*/gs, '');




    return text;
}