//test functions that will eventually be replaced
function executeConsoleInput() {
	var txt = document.getElementById('consoleTextField').value;
	rserver.execute(txt);
}

//calling uniqueID() returns a unique id for this DOM
var uniqueID = function() {
	var id=100;
	return function() {
		return id++;
	};
}();

//add some convience methods
String.prototype.startsWith = function(str) { return (this.substring(0, str.length) === str); };
String.prototype.endsWith = function(str) { return this.indexOf(str, this.length - str.length) !== -1; };


var iR = {};

iR.cmdHistory = new Array();
iR.fileTree = {};
iR.displayedDir = {};
iR.selectionStart = 0;
iR.selectionEnd = 0;
iR.userid = 0;
iR.settings = {maxHistLen: 20};
iR.isiPad = navigator.userAgent.match(/iPad/i) !== null;
iR.graphFileUrl = 'graph.svg';

iR.currentTimestamp = function() {
	var now = new Date();
	var hour = now.getHours();
	if (hour < 10)
		hour = "0" + hour;
	var mins = now.getMinutes();
	if (mins < 10)
		mins = '0' + mins;
	var seconds = now.getSeconds();
	if (seconds < 10)
		seconds = "0" + seconds;
	return (1+now.getMonth()) + '/' + now.getDate() + '/' + (now.getYear()+1900) +	' ' +
	hour + ':' + mins + ':' + seconds;
};

iR.setUserid = function(userid) {
	iR.userid = userid;
	//	var str = '<span class="statusText">Logged in as user ' + userid + '</span>\n'
	//	iR.appendConsoleText(str)
};

iR.userJoinedSession = function(login, userid) {
	var html = '<div class="sessionMsg"><span class="statusText">[' + iR.currentTimestamp() + '] ' + login + ' has joined the session</span></div>';
	iR.appendConsoleText(html);
};

iR.userLeftSession = function(login, userid) {
	var html = '<div class="sessionMsg"><span class="statusText">[' + iR.currentTimestamp() + '] ' + login + ' has left the session</span></div>';
	iR.appendConsoleText(html);
};

iR.echoInput = function(txt, username, userid) {
	var html = '<div class="sessionMsg"><span class="inputText">';
	if (username) {
		//		if (userid != iR.userid)
		html += '<span class="inputUser">' + username + ':</span> ';
	}
	html += txt + '</span></div>';
	iR.appendConsoleText(html);
};

iR.echoStdout = function(txt) {
	iR.appendConsoleText('<div class="stdoutMsg">' + txt + '</div>');
};

iR.appendHelpCommand = function(topic, pageUrl) {
	if (topic.length > 0) {
		iR.appendConsoleText('<div class="helpMsg"><a href="' + pageUrl + '">HELP: ' + topic + '</a></div>');
	}
};

iR.displayFormattedError = function(msg) {
	var html = '<div class="sessionMsg serverError" style="white-space:pre;">' + msg + '</div>';
	iR.appendConsoleText(html);
};

iR.displayError = function(msg) {
	var html = '<div class="sessionMsg"><span class="serverError">' + msg + '</span></div>';
	iR.appendConsoleText(html);
};

iR.previewImage = function(imgGroup) {
	var elems = $(imgGroup).find("a").get();
	Rc2.preview(imgGroup, elems);
};

iR.closeImagePreview = function(imgGroup) {
	Rc2.closePreview(imgGroup);
};

iR.prepareImageUrl = function(imgAnchor) {
	var str = imgAnchor.attr('href')
	if (str.indexOf('&') > 0) {
		//remove existing location info
		str = str.substring(0, str.indexOf('&'))
	}
	str = str + "&pos=" + imgAnchor.offset().left + "," + imgAnchor.offset().top;
	imgAnchor.attr('href', str)
}

iR.appendPdf = function(pdfurl, fileId, filename) {
	try {
		var ic = document.createElement('div');
		var divname = 'pdf' + new Date().getTime();
		ic.setAttribute('id', divname);
		ic.setAttribute('class', 'pdf');
		var anchorElem = document.createElement("a");
		anchorElem.setAttribute("href", pdfurl);
		var elem = document.createElement('img');
		elem.setAttribute('src', 'pdf-file.png');
		elem.setAttribute('height', 32);
		elem.setAttribute('width', 32);
		elem.setAttribute('rc2fileId', fileId);
		anchorElem.appendChild(elem);
		anchorElem.setAttribute('class', 'genFile');
		anchorElem.setAttribute('href', 'rc2file:///' + fileId + ".pdf");
		ic.appendChild(anchorElem);
		var span = document.createElement("span");
		span.innerHTML = filename;
		ic.appendChild(span);
		var outdiv = document.getElementById('consoleOutputGenerated');
		outdiv.appendChild(ic);
		outdiv.scrollTop = outdiv.scrollHeight;
	} catch (e) {
		iR.appendConsoleText("iR error " + e);
		return e;
	}
	return null;
};

iR.appendImages = function(imgArray) {
	var ic = document.createElement('div');
	var divname = 'img' + new Date().getTime();
	ic.setAttribute('id', divname);
//	if (!iR.isiPad) {
//		$(ic).addClass("imgGroup");
//		$(ic).mouseenter(function() {iR.previewImage(this); });
//		$(ic).mouseleave(function() {iR.closeImagePreview(this); });
//	}
	for (var i=0; i < imgArray.length; i++) {
		var ispan = document.createElement('span');
		ispan.setAttribute('class', 'Rimg');
		var elem = document.createElement('img');
		elem.setAttribute('src', iR.graphFileUrl);
		elem.setAttribute('height', 32);
		elem.setAttribute('width', 32);
		elem.setAttribute('class', 'gimglink');
		var anchorElem = document.createElement("a");
		anchorElem.setAttribute("href", imgArray[i]);
		anchorElem.appendChild(elem);
		anchorElem.setAttribute('class', 'genImg');
		ispan.appendChild(anchorElem);
		ic.appendChild(ispan);
	}
	var outdiv = document.getElementById('consoleOutputGenerated');
	outdiv.appendChild(ic);
	outdiv.scrollTop = outdiv.scrollHeight;
	//	$('#' + divname + " a.genImg").lightBox({fixedNavigation:true});
};

iR.fileImgForExtension = function(ext) {
	if (ext === '.png')
		return 'png-file.png';
	if (ext === '.sas')
		return 'sas-file.png';
	if (ext === '.html')
		return 'html-file.png';
	return 'plain-file.png';
}

iR.appendFiles = function(fileArray) {
	try {
		var ic = document.createElement('div');
		var divname = 'sas' + new Date().getTime();
		ic.setAttribute('id', divname);
		ic.setAttribute('class', 'sas');
		for (var i=0; i < fileArray.length; i++) {
			var aFile = fileArray[i]
			var anchorElem = document.createElement("a");
			var elem = document.createElement('img');
			elem.setAttribute('src', iR.fileImgForExtension(aFile['ext']));
			elem.setAttribute('height', 32);
			elem.setAttribute('width', 32);
			elem.setAttribute('rc2fileId', aFile['fileId']);
			anchorElem.appendChild(elem);
			anchorElem.setAttribute('class', 'genFile');
			console.log('sas file ext = ' + aFile['ext']);
			anchorElem.setAttribute('href', 'rc2file:///' + aFile['fileId'] + aFile['ext']);
			ic.appendChild(anchorElem);
			var span = document.createElement("span");
			span.innerHTML = aFile['name'];
			ic.appendChild(span);
		}
		var outdiv = document.getElementById('consoleOutputGenerated');
		outdiv.appendChild(ic);
		outdiv.scrollTop = outdiv.scrollHeight;
	} catch (e) {
		iR.appendConsoleText("iR error " + e);
	}
};

iR.restoreConsoleHTML = function(html) {
	try {
		$('#consoleOutputGenerated').append(html);
		var outdiv = document.getElementById('consoleOutputGenerated');
		outdiv.scrollTop = outdiv.scrollHeight;
	} catch (e) {
		return e.description;
	}
	return null;
};

iR.appendConsoleText = function(text) {
	var outdiv = document.getElementById('consoleOutputGenerated');
	var str = outdiv.innerHTML + text;
	outdiv.innerHTML = str;
	outdiv.scrollTop = outdiv.scrollHeight;
};

iR.showImageForTab = function(imgUrl, theTab) {
	theTab.updateDefaultImage(imgUrl);
};

iR.handleServerError = function(msg) {
	iR.appendConsoleText('<div class="statusText">&lt;&lt;' + msg + "&gt;&gt;</div>\n");
};

iR.clearConsole = function() {
	var div = document.getElementById('consoleOutputGenerated');
	div.innerHTML = '';
};

iR.checkForDump = function() {
	if ($("#dump").length < 1) {
		$('#consoleOutputGenerated').prepend($('<div id="dump" style="width:1px;height:1px;"></div>'));
	}
};
/*
 iR.toggleMatrix = function(mid) {
 var table = $("#mx" + mid)
 var tbody = table.find("tbody")
 var img = table.find("thead img").first()
 if (img.attr("src").endsWith('toggleOpen.png')) {
 img.attr("src", 'toggleClosed.png');
 tbody.fadeOut(700, function() { table.hide(); table.show();	})
 } else {
 img.attr("src", 'toggleOpen.png');
 tbody.fadeIn(700)
 }
 } */

iR.toggleMatrix = function(mid) {
	var table1 = $("#mx" + mid);
	var table2 = $("#mx" + mid + "h");
	if (table1.css('opacity') == "0") {
		table1.insertAfter(table2);
		table2.appendTo($('#dump'));
		table1.css('opacity', 1);
		table2.css('opacity', 0);
	} else {
		table2.insertAfter(table1);
		table1.appendTo($('#dump'));
		table1.css('opacity', 0);
		table2.css('opacity', 1);
	}
	/*	if (table1.css('opacity') == "0") {
	 var tmp = table2
	 table2 = table1
	 table1 = tmp
	 }
	 wrap.height(table2.outerHeight());
	 wrap.width(table2.outerWidth());
	 var dstHeight = table2.outerHeight();
	 var dstWidth = table2.outerWidth();
	 var dstOverflow=table2.css("overflow");
	 var dstArray = table2.add(wrap);
	 dstArray.height(table1.height());
	 dstArray.width(table1.width());
	 table1.fadeTo(600, 0);
	 table2.fadeTo(400, 1);
	 table2.css('overflow', 'hidden');
	 dstArray.animate({height:dstHeight, width:dstWidth}, {duration:1000});
	 */
};

iR.toggleDataFrame = function(dfid) {
	var tbody = jQuery("#df" + dfid);
	var imgdiv = jQuery("#dfl" + dfid);
	var img = jQuery("img", imgdiv)[0];
	if (img.src.endsWith('toggleOpen.png')) {
		img.src = 'toggleClosed.png';
		tbody.fadeOut(700, function() {
					  imgdiv.find('span').css('visibility', 'visible');
					  });
	} else {
		img.src = 'toggleOpen.png';
		imgdiv.find('span').css('visibility', 'hidden');
		tbody.fadeIn(700);
	}
};

iR.arrayRowsToTableRows = function(dataArray, tableElem) {
	var maxlen=0;
	var isDF=false;
	//this works for simple, not complex. if any decendent is a data frame, we need to limit to two columns
	for (var i=0; i < dataArray.length; i++) {
		var x = dataArray[i].toString();
		if (x.length > maxlen)
			maxlen = x.length;
		if (dataArray[i].hasOwnProperty("type") && dataArray[i]['type'] == 'dataframe')
			isDF=true;
	}
	var numCols = Math.floor(60 / maxlen);
	if (numCols < 1)
		numCols = 1;
	if (numCols > dataArray.length)
		numCols = dataArray.length;
	if (isDF)
		numCols = 1;
	i=0;
	var tbody = tableElem.find("tbody");
	var curRow = $("<tr>");
	for (i=0; i < dataArray.length; i++) {
		if (i % numCols === 0) {
			if (i > 0) curRow.appendTo(tbody);
			curRow = $("<tr>");
		}
		if (dataArray[i].substring || dataArray[i].toFixed)
			curRow.append($("<td>" + dataArray[i] + "</td>"));
		else
			curRow.append($("<td>").append(iR.formatComplex(dataArray[i])));
	}
	while (i++ % numCols > 0)
		curRow.append($("<td>&nbsp;</td>"));
	tbody.append(curRow);
};

/*
 iR.formatMatrix = function(theMatrix) {
 var numRows = theMatrix['rows']
 var numCols = theMatrix['cols']
 var data = theMatrix['data']
 var uid = uniqueID().toString().trim()
 var html = '<table class="ir-expvec ir-mx" id="mx' + uid + '">'
 var haveRowHeaders = theMatrix.hasOwnProperty("rownames")
 var haveColHeaders = theMatrix.hasOwnProperty("colnames") && theMatrix['colnames'].length == numCols
 if (haveColHeaders) {
 html += '<thead><tr>'
 if (haveRowHeaders) html += '<th><img src="toggleOpen.png" width="10" heigh="10" onclick="iR.toggleMatrix(\'' + uid + '\');return false">&nbsp;</th>'
 for (var i=0; i < numCols; i++)
 html += '<th>' + theMatrix['colnames'][i] + '</th>'
 html += '</tr></thead>\n'
 }
 html += '<tbody>'
 var rowNum=0
 for (var i=0; i < data.length; i++) {
 if (i % numCols == 0) {
 if (i > 0) html += '</tr>\n'
 html += '<tr>'
 if (haveRowHeaders) html += '<th>' + theMatrix['rownames'][rowNum++] + '</th>'
 }
 html += '<td>' + data[i] + '</td>'
 }
 html == '</tr>\n</tbody></table>'
 return $(html)
 }
 */
iR.formatMatrix = function(theMatrix) {
	iR.checkForDump();
	var numRows = theMatrix['rows'];
	var numCols = theMatrix['cols'];
	var data = theMatrix['data'];
	var uid = uniqueID().toString().trim();
	while ($('mx' + uid).length > 0)
		uid = uniqueID().toString().trim();
	var table1 = $('<table class="ir-expvec ir-mx" id="mx' + uid + '"></table>');
	var table2 = $('<table class="ir-expvec ir-mx" id="mx' + uid + 'h" style="opacity=0;"></table>');
	var haveRowHeaders = theMatrix.hasOwnProperty("rownames");
	var haveColHeaders = theMatrix.hasOwnProperty("colnames") && theMatrix['colnames'].length == numCols;
	if (haveColHeaders) {
		var thead = $("<thead>");
		var headrow = $("<tr>");
		headrow.appendTo(thead);
		var thead2 = $("<thead>");
		var headrow2 =$("<tr>");
		headrow2.appendTo(thead2);
		if (haveRowHeaders) {
			headrow.append($('<th><img src="toggleOpen.png" class="toggleImg" onclick="iR.toggleMatrix(\'' + uid + '\');return false">&nbsp;</th>'));
			headrow2.append($('<th><img src="toggleClosed.png" class="toggleImg" onclick="iR.toggleMatrix(\'' + uid + '\');return false">&nbsp;</th>'));
		}
		for (var i=0; i < numCols; i++) {
			headrow.append('<th>' + theMatrix['colnames'][i] + '</th>');
			headrow2.append('<th>' + theMatrix['colnames'][i] + '</th>');
		}
		table1.append(thead);
		table2.append(thead2);
	}
	var tbody=$('<tbody></tbody>');
	table1.append(tbody);
	var rowNum=0;
	var html = '';
	for (i=0; i < data.length; i++) {
		if (i % numCols === 0) {
			if (i > 0) html += '</tr>\n';
			html += '<tr>';
			if (haveRowHeaders) html += '<th>' + theMatrix['rownames'][rowNum++] + '</th>';
		}
		html += '<td>' + data[i] + '</td>';
	}
	html += '</tr>';
	tbody.append(html);
	if (haveColHeaders) {
		var wrap = $('<div id="mx' + uid + 'w" style="position:relative;margin-bottom:8px;"></div>');
		wrap.append(table1);
		table2.css('opacity', 0);
		table2.appendTo($("#dump"));
		setTimeout(function() {
				   wrap.css("min-width", table1.outerWidth()+10);
				   wrap.width(table1.outerWidth());
				   table2.css("min-width", table1.outerWidth()+10);
				   }, 100);
		return wrap;
	}
	return table1;
};

iR.formatDataFrame = function(theFrame) {
	var colTitles = theFrame['colTitles'];
	var rowTitles = theFrame['rowTitles'];
	var colData = theFrame['rows'];
	var id = uniqueID().toString();
	var dfid = 'df' + id;
	var html = '<table class="ir-expvec ir-df" id="' + dfid + '">';
	var headRow = '<thead><tr>';
	var capt = '<div class="ir-df-label" id="dfl' + id + '"><img src="toggleOpen.png" width="10" heigh="10" onclick="iR.toggleDataFrame(\'' + id + '\')"><span style="visibility:hidden">';
	if (rowTitles) headRow += '<th>&nbsp;</th>';
	for (var i=0; i < colTitles.length; i++) {
		headRow += '<th class="ir-df-ch">' + colTitles[i] + '</th>';
		if (i > 0) capt += ',';
		capt += colTitles[i];
	}
	headRow += '</tr></thead>\n';
	capt += '</span></div>';
	html = capt + html + headRow + '<tbody id="dfb' + id.toString() + '">';
	var rowCount = colData[0].length;
	for (i=0; i < rowCount; i++) {
		html += '<tr>';
		if (rowTitles) html += '<th class="ir-df-rh">' + rowTitles[i] + "</th>";
		for (var j=0; j < colData.length; j++)
			html += '<td>' + colData[j][i] + '</td>';
		html += '</tr>\n';
	}
	html += '</tbody></table>\n';
	return $(html);
};

iR.formatHash = function(theHash) {
	var table = $('<table class="ir-expvec"><tbody></tbody></table>');
	if (theHash['type'] == 'dataframe')
		return iR.formatDataFrame(theHash);
	var tbody = table.find("tbody");
	for (key in theHash) {
		if (theHash.hasOwnProperty(key)) {
			//it is a value to output
			var row = $("<tr>");
			row.appendTo(tbody);
			row.append($("<th>").append(key));
			var cell = $('<td class="ir-expvectnest">');
			var val = theHash[key];
			cell.append(iR.formatList(val));
			row.append(cell);
		}
	}
	return table;
};

iR.formatList = function(theList) {
	var table = $('<table class="ir-expvec"><tbody></tbody></table>');
	if (theList.substring) {
		return theList;
	} else if (theList.toFixed) {
		return $("<td>" + theList + "</td>");
	} else if (theList instanceof Array) {
		if (theList.length == 1 && (theList[0].substring || theList[0].toFixed)) {
			return theList[0].toString();
		} else {
			iR.arrayRowsToTableRows(theList, table);
			return table;
		}
	} else {
		if (theList['type'] == 'matrix') {
			return iR.formatMatrix(theList);
		} else if (theList['type'] == 'dataframe') {
			return iR.formatDataFrame(theList);
		}
		//it is a hash
		return iR.formatHash(theList);
	}
	return table;
};

iR.formatComplex = function(dataArray) {
	if (dataArray.length == 1) 
		return iR.formatList(dataArray[0]);
	else
		return iR.formatList(dataArray);
};

iR.appendComplexResults = function(dataArray) {
	var newElem = iR.formatComplex(dataArray);
	newElem.addClass("ir-rt-root");
	newElem.appendTo($("#consoleOutputGenerated"));
	//all the nested tables are now marked as such
	$(".ir-expvec", newElem).addClass("subtable");
	//set all dataframe labels to be the width of their table
	$(".ir-df-label").each(function(idx) {
						   $(this).css('width', $(this).next(".ir-df").css('width'));
						   });
	$("#consoleOutputGenerated").scrollTop(document.getElementById("consoleOutputGenerated").scrollHeight);
};

iR.appendResults = function(dataArray) {
	if (typeof dataArray[0] != "string")
		return this.appendNumericResults(dataArray);
	var table = $('<table class="ir-expvec"><tbody></tbody></table>');
	iR.arrayRowsToTableRows(dataArray, table);
	table.appendTo($('#consoleOutputGenerated'));
	return null;
};

//eventually this should align the decimal places. for now, we just do it as strings
iR.appendNumericResults = function(dataArray) {
	var txt = '<table class="ir-expvec">';
	var maxlen=0;
	for (var i=0; i < dataArray.length; i++) {
		var x = dataArray[i].toString();
		if (x.length > maxlen)
			maxlen = x.length;
	}
	var numCols = Math.floor(60 / maxlen);
	if (numCols < 1)
		numCols = 1;
	if (numCols > dataArray.length)
		numCols = dataArray.length;
	i=0;
	for (i=0; i < dataArray.length; i++) {
		if (i % numCols === 0) {
			if (i > 0) txt += "</tr>\n";
			txt += "<tr>";
		}
		txt += "<td>" + dataArray[i] + "</td>";
	}
	while (i++ % numCols > 0)
		txt += '<td>&nbsp;</td>';
	txt += "</tr>\n";
	txt += "</table>";
	iR.appendConsoleText(txt);
};

iR.clearSavedSelection = function() {
	this.selectionStart=0;
	this.selectionEnd=0;
};

iR.increaseFontSize = function() {
	var curSize = parseFloat($('body').css('font-size'));
	if (curSize < 36)
		$('body').css('font-size', curSize + 2);
};

iR.decreaseFontSize = function() {
	var curSize = parseFloat($('body').css('font-size'));
	if (curSize > 8)
		$('body').css('font-size', curSize - 2);
};

iR.doSetup = function() {
	if (!iR.isiPad) {
		$('body').delegate('.genImg', 'click', function() {iR.prepareImageUrl($(this))})
		//restore handlers for any image groups
//		$(".imgGroup").mouseenter(function() {iR.previewImage(this); });
//		$(".imgGroup").mouseleave(function() {iR.closeImagePreview(this); });
	}
};
