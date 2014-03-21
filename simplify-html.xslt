<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:template match="@*|node()" priority="-3">
        <xsl:copy/>
    </xsl:template>
    <xsl:template match="p|i|em|strong|b|ol|ul|li|a|img">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="*"/>
</xsl:stylesheet>